describe ManageIQ::Providers::Lenovo::PhysicalInfraManager do
  it 'ems_type should be lenovo_ph_infra' do
    expect(described_class.ems_type).to eq('lenovo_ph_infra')
  end

  it "description should be 'Lenovo XClarity'" do
    expect(described_class.description).to eq("Lenovo XClarity")
  end

  describe ".verify_credentials" do
    let(:params_for_create) do
      {
        "endpoints"       => {"default" => {"hostname" => "xclarity.localdomain", "port" => 443}},
        "authentications" => {"default" => {"userid" => "admin", "password" => "password"}}
      }
    end

    it "calls validate_configuration on xclarity client" do
      expect(described_class).to receive(:validate_connection)

      described_class.verify_credentials(params_for_create)
    end

    context "with an existing provider" do
      let(:ems) { FactoryBot.create(:physical_infra_with_authentication) }
      let(:params_for_create) do
        {
          "id"              => ems.id,
          "endpoints"       => {"default" => {"hostname" => "xclarity.localdomain", "port" => 443}},
          "authentications" => {"default" => {"userid" => "admin"}}
        }
      end

      it "uses the existing password if another isn't specified" do
        expect(described_class).to receive(:validate_connection)

        described_class.verify_credentials(params_for_create)
      end
    end
  end
end
