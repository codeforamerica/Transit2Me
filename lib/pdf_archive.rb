$: << File.expand_path('../../lib', __FILE__)

require 'bundler'
Bundler.require

# Application module
module PdfArchive
  def self.environment
    ENV['RACK_ENV'] || 'development'
  end

  def self.root
    @root ||= Pathname(File.expand_path('../..', __FILE__))
  end
end

# MongoMapper setup
mongo_url = ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI'] || "mongodb://localhost:27017/pdf_archive-#{PdfArchive.environment}"
uri = URI.parse(mongo_url)
database = uri.path.gsub('/', '')
MongoMapper.connection = Mongo::Connection.new(uri.host, uri.port, {})
MongoMapper.database = database
if uri.user.present? && uri.password.present?
  MongoMapper.database.authenticate(uri.user, uri.password)
end

# CarrierWave setup
require 'carrierwave/orm/mongomapper'
CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY']
  }

  config.fog_directory  = ENV['BUCKET_NAME']
  config.fog_public     = true                                    # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end

# Grim Production Config
if PdfArchive.environment == "production"
  Grim.processor = Grim::MultiProcessor.new([
    Grim::ImageMagickProcessor.new({:ghostscript_path => PdfArchive.root.join('bin', '9.04', 'gs')}),
    Grim::ImageMagickProcessor.new({:ghostscript_path => PdfArchive.root.join('bin', '9.02', 'gs')})
  ])
end

# require pdf uploader, document model, and process pdf job
require 'uploader'
require 'pdf_uploader'
require 'preview_store'
require 'document'
require 'process_pdf'

# Routes
set :public_folder, "#{PdfArchive.root}/public"

get '/' do
  erb :home
end

post '/' do
  if params['pdf']
    document = Document.create!(params)
    Qu.enqueue(ProcessPdf, document.id)
  end

  erb :home
end

get '/search' do
  @documents = Document.search(params['q'])
  erb :home
end
