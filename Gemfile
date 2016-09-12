# Declare your gem's dependencies in manageiq-providers-amazon.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :test do
  gem "codeclimate-test-reporter", :require => false, :git => "git://github.com/codeclimate/ruby-test-reporter", :branch => "master"
  gem 'guard'
	
end


group :test, :development do
  gem "rspec"

end

unless dependencies.detect { |d| d.name == "xclarity_client" }
  gem "xclarity_client", :git => "git://github.com/maas-ufcg/xclarity_client", :branch => "master"
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.



# Load Gemfile with dependencies from manageiq
#eval_gemfile(File.expand_path("spec/manageiq/Gemfile", __dir__))
