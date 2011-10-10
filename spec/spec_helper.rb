ENV['RACK_ENV'] = 'test'

require 'bundler'
Bundler.require 'test'
require 'rack/test'
require 'fileutils'

require File.expand_path(File.dirname(__FILE__) + "/../lib/pdf_archive")

set :environment, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before do
    MongoMapper.database.collections.each(&:remove)
  end

  def pdf_fixture(filename)
    fixture_path = File.expand_path("./spec/fixtures/")
    file_path = File.join(fixture_path, filename)
    File.open(file_path)
  end

  def tmp_dir
    path = File.expand_path("./tmp")
    Dir.mkdir(path) unless File.directory?(path)
    path
  end

  def app
    Sinatra::Application
  end

  config.after(:all) do
    FileUtils.rm_rf(tmp_dir)
  end
end