require "xclarity_client"
require 'webmock/rspec'

describe ManageIQ::Providers::Lenovo::PhysicalInfraManager::PhysicalServer do
  describe "remote console" do
    before :each do
      @physical_infra_manager = FactoryGirl.create(:physical_infra,
                                                   :name      => "LXCA",
                                                   :hostname  => "10.243.9.123",
                                                   :port      => "443",
                                                   :ipaddress => "https://10.243.9.123")
      @physical_server = FactoryGirl.create(:lenovo_physical_server,
                                            :name                  => "IMM2-e41f13ed5a1e",
                                            :ems_ref               => "BD775D06821111E189A3E41F13ED5A1A",
                                            :ext_management_system => @physical_infra_manager)
      auth = FactoryGirl.create(:authentication,
                                :userid   => "admin",
                                :password => "password",
                                :authtype => "default")
      @physical_infra_manager.authentications = [auth]
      @mocked_remote_access_resource = {:resource => 'https://dummy.address.com', :type => :url}
      allow(@physical_infra_manager).to receive(:connect).with(hash_including(:host => "10.243.9.123", :port => 443)) do
        double_client = double("XClarityClient")
        allow(double_client).to receive(:remote_control).with("BD775D06821111E189A3E41F13ED5A1A") do
          @mocked_remote_access_resource
        end
        double_client
      end
    end

    it "requests the remote console" do
      expect(@physical_server.remote_console_acquire_resource(nil, nil)).to eq(@mocked_remote_access_resource)
    end
  end
end
