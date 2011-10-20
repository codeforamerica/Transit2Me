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
mongo_url = ENV['MONGOHQ_URL'] || "mongodb://localhost:27017/pdf_archive-#{PdfArchive.environment}"
uri = URI.parse(mongo_url)
database = uri.path.gsub('/', '')
MongoMapper.connection = Mongo::Connection.new(uri.host, uri.port, {})
MongoMapper.database = database

# Qu setup
Qu.configure do |c|
  c.connection = MongoMapper.connection.db('qu')
end

# CarrierWave setup
require 'carrierwave/orm/mongomapper'

# require pdf uploader and document model
require 'pdf_uploader'
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