require 'rubygems'
require 'bundler/setup'

task :console do
  exec "irb -r ./lib/pdf_archive"
end

if ENV['RACK_ENV'] != 'production'
  require 'rspec/core/rake_task'
  desc "Run specs"
  task :spec do
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.pattern = './spec/**/*_spec.rb'
    end
  end
  task :default => :spec
end

require 'qu/tasks'
task :environment do
  require './lib/pdf_archive'
end