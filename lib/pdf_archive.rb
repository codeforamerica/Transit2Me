$: << File.expand_path('../../lib', __FILE__)

require 'bundler'
Bundler.require

get '/' do
  erb :home
end