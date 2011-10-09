require 'bundler'
Bundler.require 'test'
require 'rack/test'

require File.expand_path(File.dirname(__FILE__) + "/../lib/pdf_archive")

set :environment, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def app
  Sinatra::Application
end