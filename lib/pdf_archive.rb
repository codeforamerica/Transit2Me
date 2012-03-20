$: << File.expand_path('../../lib', __FILE__)

require 'bundler'
Bundler.require

# for URL fetching
require 'uri'
require 'net/http'

# Application module
module Transit2Me
  def self.environment
    ENV['RACK_ENV'] || 'development'
  end

  def self.root
    @root ||= Pathname(File.expand_path('../..', __FILE__))
  end
end

# MongoMapper setup
mongo_url = ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI'] || "mongodb://localhost:27017/pdf_archive-#{Transit2Me.environment}"
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
if Transit2Me.environment == "production"
  Grim.processor = Grim::MultiProcessor.new([
    Grim::ImageMagickProcessor.new({:ghostscript_path => Transit2Me.root.join('bin', '9.04', 'gs')}),
    Grim::ImageMagickProcessor.new({:ghostscript_path => Transit2Me.root.join('bin', '9.02', 'gs')})
  ])
end

require 'exceptional'
set :raise_errors, true
use Rack::Exceptional, ENV['EXCEPTIONAL_API_KEY'] if ENV['RACK_ENV'] == 'production' && ENV['EXCEPTIONAL_API_KEY']

# transit stuff
require 'transitevent'

# Routes
set :public_folder, "#{Transit2Me.root}/public"

class BartStation
   def initialize(id, latlng, name)
      @id=id
      @latlng=latlng
      @name=name
   end
   def getid()
     return @id
   end
   def getname()
     return @name
   end
end

def bart_id_to_name(bid)
  stations = [
	BartStation.new("19TH", [37.8076295249,-122.268869226], "19th St. Oakland" ),
	BartStation.new("24TH",[37.752411,-122.418292],"24th St. Mission"),
	BartStation.new("ASHB",[37.853061,-122.269946],"Ashby"),
	BartStation.new("BALB",[37.7219808677,-122.447414196],"Balboa Park"),
	BartStation.new("COLS",[37.7542813804,-122.197788821],"Coliseum/Oakland Airport"),
		BartStation.new("CONC",[37.9720158312,-122.029861348],"Concord"),
		BartStation.new("DALY",[37.7061205485,-122.469080674],"Daly City"),
		BartStation.new("DBRK",[37.8698684624,-122.268050932],"Downtown Berkeley"),
		BartStation.new("DELN",[37.9256508785,-122.31721887],"El Cerrito del Norte"),
		BartStation.new("DUBL",[37.7016736171,-121.900352519],"Dublin/Pleasanton"),
		BartStation.new("EMBR",[37.7930224405,-122.396813153],"Embarcadero"),
		BartStation.new("FRMT",[37.5573342821,-121.976395442],"Fremont"),
		BartStation.new("FTVL",[37.7746238056,-122.224327698],"Fruitvale"),
		BartStation.new("GLEN",[37.7329415443,-122.434114331],"Glen Park"),
		BartStation.new("HAYW",[37.6703868939,-122.088002125],"Hayward"),
		BartStation.new("LAFY",[37.8934254672,-122.123798472],"Lafayette Park"),
		BartStation.new("LAKE",[37.7976023716,-122.265498391],"Lake Merritt"),
		BartStation.new("MCAR",[37.8284094079,-122.267187102],"MacArthur"),
		BartStation.new("MONT",[37.7893359611,-122.401485489],"Montgomery St."),
		BartStation.new("NBRK",[37.87402614,-122.283881911],"North Berkeley"),
		BartStation.new("NCON",[38.002576647,-122.025106029],"North Concord/Martinez"),
		BartStation.new("ORIN",[37.8783608699,-122.183791135],"Orinda"),
		BartStation.new("PHIL",[37.9277362737,-122.056847034],"Pleasant Hill/Contra Costa Centre"),
		BartStation.new("PITT",[38.0189343386,-121.941904488],"Pittsburg/Bay Point"),
		BartStation.new("PLZA",[37.9030588009,-122.29927151],"El Cerrito Plaza"),
		BartStation.new("BAYF",[37.6978321791,-122.127858508],"Bay Fair"),
		BartStation.new("CAST",[37.6907303057,-122.077460002],"Castro Valley"),
		BartStation.new("CIVC",[37.7796055874,-122.413851084],"Civic Center/UN Plaza"),
		BartStation.new("19TH_N",[37.8076295249,-122.268869226],"19th St. Oakland"),
		BartStation.new("WDUB",[37.6998,-121.9281],"West Dublin/Pleasanton"),
		BartStation.new("POWL",[37.7849710021,-122.407012285],"Powell St."),
		BartStation.new("ROCK",[37.8441838514,-122.252731522],"Rockridge"),
		BartStation.new("SANL",[37.7226192073,-122.161311154],"San Leandro"),
		BartStation.new("SHAY",[37.6347995391,-122.057550587],"South Hayward"),
		BartStation.new("SSAN",[37.66433,-122.44399],"South San Francisco"),
		BartStation.new("UCTY",[37.591202687,-122.017857962],"Union City"),
		BartStation.new("WCRK",[37.9046388803,-122.068018135],"Walnut Creek"),
		BartStation.new("WOAK",[37.8046747595,-122.294582214],"West Oakland"),
		BartStation.new("COLM",[37.6845808931,-122.467369242],"Colma"),
		BartStation.new("MLBR",[37.600006,-122.386534],"Millbrae"),
		BartStation.new("RICH",[37.9371699076,-122.3534001],"Richmond"),
		BartStation.new("SBRN",[37.637143,-122.415912],"San Bruno"),
		BartStation.new("SFIA",[37.6159,-122.392534],"San Francisco Int"),
		BartStation.new("OAK",[37.712811,-122.213165],"Oakland Airport Terminals"),
		BartStation.new("MCAR_S",[37.8284094079,-122.267187102],"MacArthur"),
		BartStation.new("12TH",[37.8030927157,-122.271655014],"12th St. Oakland City Center"),
		BartStation.new("16TH",[37.765228,-122.419478],"16th St. Mission")
  ]
  stations.each do |station|
    if station.getid() == bid
      return station.getname()
    end
  end
  return bid
end

get '/transit' do
  if params['eventname']
    @tevents = TransitEvent.search(params['eventname'])
    
    eventDest = @tevents.first.gotostation
    eventMMDDYYYY = @tevents.first.dateof
    eventTime = @tevents.first.timeof
    eventTime = eventTime.sub(' ','')
    
    closestStation = 'CONC'
    
    url = 'http://api.bart.gov/api/sched.aspx?cmd=arrive&orig=' + closestStation + '&dest=' + eventDest + '&date=' + eventMMDDYYYY + '&b=2&a=0&l=0&time=' + eventTime + '&key=PJHS-I4ER-TEQY-MHSU'
    url = URI.parse(url)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get('/api/sched.aspx?cmd=arrive&orig=' + closestStation + '&dest=' + eventDest + '&date=' + eventMMDDYYYY + '&b=2&a=0&l=0&time=' + eventTime + '&key=PJHS-I4ER-TEQY-MHSU')
    }
    bartschedule = res.body

    narrative = ''
    trips = bartschedule.split('<trip')
    tripCount = 0
    trips.each do |trip|
      tripCount = tripCount + 1
      if tripCount == 1
        next
      end
      narrative = narrative + '<ol>'
      legs = trip.split('<leg')
      legCount = 0
      legs.each do |leg|
        legCount = legCount + 1
        if legCount == 1
          next
        end
        origin = leg.slice( leg.index('origin') + 8 .. leg.length )
        origin = origin.slice( 0 .. origin.index('"') - 1 )
        origin = bart_id_to_name(origin)

        originTime = leg.slice( leg.index('origTimeMin') + 13 .. leg.length )
        originTime = originTime.slice( 0 .. originTime.index('"') - 1 )

        trainhead = leg.slice( leg.index('trainHeadStation') + 18 .. leg.length )
        trainhead = trainhead.slice(0 .. trainhead.index('"') - 1)
        trainhead = bart_id_to_name(trainhead)

        destination = leg.slice( leg.index('destination') + 13 .. leg.length )
        destination = destination.slice( 0 .. destination.index('"') - 1)
        destination = bart_id_to_name(destination)

        destinationTime = leg.slice( leg.index('destTimeMin') + 13 .. leg.length )
        destinationTime = destinationTime.slice( 0 .. destinationTime.index('"') - 1)

        if legCount == 2
          narrative = narrative + '<li>Go to ' + origin + ' BART Station</li>'
          narrative = narrative + '<li>Take the ' + originTime + ' train toward ' + trainhead + '</li>'
        end
        if legCount >= legs.length
          narrative = narrative + '<li>Exit at the ' + destination + ' BART Station around ' + destinationTime
        else
          narrative = narrative + '<li>Transfer at the ' + destination + ' BART Station around ' + destinationTime
        end
      end
      narrative = narrative + '</ol>'
    end
    if bartschedule.index('strong') != nil
      if bartschedule.index('pounds') != nil
        carbon = bartschedule.slice( bartschedule.index('strong') + 7 .. bartschedule.index('pounds') - 2 )
      end
    end
    erb :transitposted, :locals => { :narrative => url, :carbon => carbon }
  else
    erb :transit
  end
end

post '/transit' do
  if params['eventname']
    t_evt = TransitEvent.create!(params)
  end
end

get '/' do
  erb :transit
end

#get '/search' do
#  @documents = Document.search(params['q'])
#  erb :home
#end
