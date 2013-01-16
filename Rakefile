# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "activerecord-model-spaces"
  gem.homepage = "http://github.com/mccraigmccraig/activerecord-model-spaces"
  gem.license = "MIT"
  gem.summary = %Q{manage activerecord model to table mappings}
  gem.description = %Q{map activerecord models to tables depending on context}
  gem.email = "mccraigmccraig@gmail.com"
  gem.authors = ["mccraig mccraig of the clan mccraig"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

RSpec::Core::RakeTask.new(:simplecov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  ENV['SIMPLECOV'] = "true"
  # `open coverage/index.html`
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "activerecord-model-spaces #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
