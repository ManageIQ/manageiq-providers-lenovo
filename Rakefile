begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Dir.glob('./lib/tasks/**/*.rake').each { |r| load r}

# require 'rdoc/task'
#
# RDoc::Task.new(:rdoc) do |rdoc|
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title    = 'Blorgh'
#   rdoc.options << '--line-numbers'
#   rdoc.rdoc_files.include('README.md')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end

APP_RAKEFILE = File.expand_path("../spec/manageiq/Rakefile", __FILE__)


# load 'rails/tasks/statistics.rake'



# require 'bundler/gem_tasks'

# require 'rake/testtask'
#
# Rake::TestTask.new(:test) do |t|
#   t.libs << 'lib'
#   t.libs << 'test'
#   t.pattern = 'test/**/*_test.rb'
#   t.verbose = false
# end
#
#
# task default: :test
