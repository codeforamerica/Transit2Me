$: << File.expand_path('../spec', __FILE__)

require 'rubygems'
require 'bundler/setup'

require 'rspec/core/rake_task'

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

task :console do
  exec "irb -Iapp -r pdf_archive"
end

task :default => :spec