require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

task :console do
  exec "irb -Iapp -r ./lib/pdf_archive"
end

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end
task :default => :spec

require 'qu/tasks'
task :environment do
  require './lib/pdf_archive'
end