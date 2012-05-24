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
   def getlat()
     return @latlng[0]
   end
   def getlng()
     return @latlng[1]
   end
end

class MaconStop
   def initialize(id, name, route, lnglat)
      @id=id
      @lnglat=lnglat
      @name=name
      @route=route
   end
   def getid()
     return @id
   end
   def getname()
     return @name
   end
   def getlat()
     return @lnglat[1]
   end
   def getlng()
     return @lnglat[0]
   end
   def getroute()
     return @route
   end
   def hasroute(askroute)
     # checks for this route and any code -I for Inbound, -O for Outbound, etc
     if @route.index(askroute) != nil or @route.index(askroute + "-O") != nil or @route.index(askroute + "-I") != nil or @route.index(askroute + "B") != nil or @route.index(askroute + "C") != nil
       return true
     end
     return false
   end
end

def closest_macon(lat, lng, weekday)
  stations = [
  MaconStop.new("1","MLK and Riverside",["11"],[-83.621172,32.837522]),
  MaconStop.new("2","Coliseum Drive",["11"],[-83.618296,32.84122]),
  MaconStop.new("3","Coliseum Drive",["11"],[-83.618426,32.841512]),
  MaconStop.new("4","Coliseum Drive and Main Street",["11-I"],[-83.615983,32.843738]),
  MaconStop.new("5","Main Street and Ft Hill Street",["11-I"],[-83.612418,32.845216]),
  MaconStop.new("6","Main Street",["11"],[-83.608473,32.846632]),
  MaconStop.new("7","Main Street and Leaf Street",["11"],[-83.61008,32.846021]),
  MaconStop.new("8","Main Street",["11"],[-83.608501,32.846743]),
  MaconStop.new("9","Main Street",["11"],[-83.60710,32.847095]),
  MaconStop.new("10","Main Street and Short Street",["11"],[-83.607469,32.84797]),
  MaconStop.new("11","Emery HWY and Reese Street",["11"],[-83.604525,32.848368]),
  MaconStop.new("12","Emery Hwy and Lexington Street",["11-O"],[-83.617477,32.848278]),
  MaconStop.new("13","Jeffersonville Road and Magnolia Drive SB",["11"],[-83.600712,32.849623]),
  MaconStop.new("14","Jefersonville Road and Magnolia Drive NB",["11"],[-83.600728,32.849525]),
  MaconStop.new("15","Jeffersonville Road and Indian Cir",["11"],[-83.599319,32.850037]),
  MaconStop.new("16","Jeffersonville Road and Dorothy Street",["11"],[-83.599319,32.85012]),
  MaconStop.new("17","Jeffersonvillle Road and Baker Street NB",["11"],[-83.59669,32.851026]),
  MaconStop.new("18","Jeffersonville Road and Baker Street SB",["11"],[-83.596737,32.851112]),
  MaconStop.new("19","Jeffersonville Road and Wallace Drive NB",["11"],[-83.595182,32.851612]),
  MaconStop.new("20","Jeffersonville Road and Wallace Drive SB",["11"],[-83.595226,32.851711]),
  MaconStop.new("21","Jeffersonville Road and Artic Circle",["11"],[-83.591460,32.852410]),
  MaconStop.new("22","Jeffersonville Road and Rowster Drive",["11"],[-83.590890,32.852272]),
  MaconStop.new("23","Jeffersonville Road and Millerfield Road",["11"],[-83.588797,32.852324]),
  MaconStop.new("24","Jeffersonville Road and Millerfield Road",["11"],[-83.588547,32.852434]),
  MaconStop.new("25","Jeffersonville Road and Strozier St NB",["11-O"],[-83.587734,32.853690]),
  MaconStop.new("26","Jeffersonville Road and Strozier St SB",["11"],[-83.587895,32.853715]),
  MaconStop.new("27","Pine Hill Drive",["11-O"],[-83.589776,32.861543]),
  MaconStop.new("28","Shurling Drive",["11-O"],[-83.592557,32.861593]),
  MaconStop.new("29","E. Pine Hill Drive and New Clinton Road",["11-O"],[-83.586312,32.86078]),
  MaconStop.new("30","Lainey Avenue",["11-O"],[-83.568451,32.865903]),
  MaconStop.new("31","Donald Avenue and Millerfield Road",["11-O"],[-83.582797,32.859028]),
  MaconStop.new("32","Lainey Avenue",["11-O"],[-83.569252,32.866487]),
  MaconStop.new("33","Lainey Avenue",["11-O"],[-83.570882,32.867891]),
  MaconStop.new("34","Commodore Drive",["11"],[-83.574642,32.868131]),
  MaconStop.new("35","Commodore Drive",["11"],[-83.572537,32.869974]),
  MaconStop.new("36","Commodore Drive",["11"],[-83.571390,32.870722]),
  MaconStop.new("37","Millerfield Road",["11"],[-83.57068,32.863925]),
  MaconStop.new("38","Millerfield Road and Jordan Avenue",["11"],[-83.574397,32.861015]),
  MaconStop.new("40","Coliseum Drive and Friendship",["11-O"],[-83.616591,32.847211]),
  MaconStop.new("41","Jeffersonville Road and Ocmulgee East BLVD",["11"],[-83.574193,32.841596]),
  MaconStop.new("42","Jeffersonville Road near Apartments",["11"],[-83.569513,32.842249]),
  MaconStop.new("43","Jeffersonville Road and Finneydale Drive",["11"],[-83.562255,32.84195]),
  MaconStop.new("44","Lexington Street and Woolfolk Street",["11-O"],[-83.617612,32.849637]),
  MaconStop.new("45","Woolfolk Street and Center Street",["11-O"],[-83.615950,32.849630]),
  MaconStop.new("46","Woolfolk Street and Womack Street",["11-O"],[-83.614289,32.849648]),
  MaconStop.new("47","Woolfolk Street and Maynard Street",["11-O"],[-83.610997,32.849634]),
  MaconStop.new("48","Jordan Avenue NB",["11"],[-83.573493,32.855718]),
  MaconStop.new("49","Jordan Avenue SB",["11"],[-83.573982,32.855454]),
  MaconStop.new("50","Jordan Avenue and Recreation Road",["11"],[-83.571406,32.853555]),
  MaconStop.new("51","Recreation Road",["11"],[-83.569318,32.852974]),
  MaconStop.new("52","Recreation Road",["11"],[-83.567878,32.852162]),
  MaconStop.new("53","Mogul Rd and Jeffersonville Road",["11"],[-83.557296,32.842634]),
  MaconStop.new("55","Mogule Road and Kings Park Circle",["11"],[-83.556001,32.846432]),
  MaconStop.new("56","Kings Park Circle",["11"],[-83.555170,32.845808]),
  MaconStop.new("57","Kings Park Circle",["11"],[-83.553558,32.847181]),
  MaconStop.new("58","Kings Park Circle",["11"],[-83.552921,32.847629]),
  MaconStop.new("59","Kings Park Circle",["11"],[-83.549980,32.848037]),
  MaconStop.new("60","Queens Circle and Masseyville Road",["11"],[-83.54953,32.849303]),
  MaconStop.new("61","Masseyville Road",["11"],[-83.55194,32.848751]),
  MaconStop.new("62","Masseyville Road",["11"],[-83.553585,32.848167]),
  MaconStop.new("63","Masseyville Road and Mogul Raod",["11"],[-83.555924,32.847897]),
  MaconStop.new("64","Recreation Road and Roseview Drive",["11"],[-83.586319,32.851840]),
  MaconStop.new("65","Recreation Road",["11"],[-83.582968,32.85149]),
  MaconStop.new("66","Recreation Road",["11"],[-83.580477,32.852279]),
  MaconStop.new("67","Recreation Road and Mornigside Road",["11"],[-83.579175,32.852307]),
  MaconStop.new("68","Morningside Road",["11"],[-83.57843,32.850372]),
  MaconStop.new("69","Morningside Road and Jeffersonville Road",["11"],[-83.57943,32.848345]),
  MaconStop.new("70","Jeffersonville Road and McCall Road",["11"],[-83.579011,32.847378]),
  MaconStop.new("71","Jeffersonville Road",["11"],[-83.565711,32.842386]),
  MaconStop.new("72","Spring Street and Riverside",["4"],[-83.630640,32.843091]),
  MaconStop.new("73","1st Street and Cherry Street",["0"],[-83.630577,32.837339]),
  MaconStop.new("74","Spring Street and Riverside",["4"],[-83.63037,32.843069]),
  MaconStop.new("75","Emery Highway near Chi-Chesters",["4-O"],[-83.624675,32.848096]),
  MaconStop.new("76","Bibb County Health Department",["4-O"],[-83.622284,32.847570]),
  MaconStop.new("77","2nd Street near Gray Highway",["4-O"],[-83.620739,32.848677]),
  MaconStop.new("78","Hall Street and Lexington Street",["4-O"],[-83.617784,32.852519]),
  MaconStop.new("79","Hall Street",["4-O"],[-83.616856,32.852536]),
  MaconStop.new("80","Hall Street and Center Street",["4-O"],[-83.615976,32.852552]),
  MaconStop.new("81","Hall Street",["4-O"],[-83.61517,32.852549]),
  MaconStop.new("82","Emery Highway near Chi-Chesters",["4-O"],[-83.625407,32.848140]),
  MaconStop.new("83","Hall Street and Womack Street",["4-O"],[-83.614267,32.852545]),
  MaconStop.new("84","Hall Street",["4-O"],[-83.613461,32.85250]),
  MaconStop.new("85","Hall Street and Maynard Street",["4-O"],[-83.61096,32.852551]),
  MaconStop.new("86","Hall Street",["4-O"],[-83.611775,32.852534]),
  MaconStop.new("87","Hall Street and Ft Hill Street",["4-O"],[-83.612581,32.852537]),
  MaconStop.new("88","Maynard Street and Taylor Street",["4-O"],[-83.610878,32.855416]),
  MaconStop.new("89","Maynard Street and Williams Street",["4-O"],[-83.610845,32.856838]),
  MaconStop.new("90","Maynard Street and Morrow Avenue",["4-O"],[-83.610787,32.858302]),
  MaconStop.new("91","Maynard Street and Shurling Drive",["4-O"],[-83.610756,32.859353]),
  MaconStop.new("92","Shurling Drive and Kitchens Street",["4-O"],[-83.607530,32.859648]),
  MaconStop.new("93","Kitchens Street",["4-O"],[-83.607381,32.859957]),
  MaconStop.new("94","Haywood Road",["4-O"],[-83.606553,32.863396]),
  MaconStop.new("96","Kitchens Street and Haywood Road",["4-O"],[-83.607384,32.863400]),
  MaconStop.new("97","Kitchens Street and Haywood Road",["4-O"],[-83.604501,32.863449]),
  MaconStop.new("98","Kitchens Street",["4-O"],[-83.605054,32.864791]),
  MaconStop.new("99","Kitchens Street",["4-O"],[-83.606683,32.866056]),
  MaconStop.new("100","Kitchens Street",["4-O"],[-83.607685,32.866061]),
  MaconStop.new("101","Kitchens Street",["4-O"],[-83.608210,32.86418]),
  MaconStop.new("102","Kitchens",["4-O"],[-83.607487,32.862576]),
  MaconStop.new("103","Shurling Drive and Gray Highway",["4"],[-83.614736,32.859639]),
  MaconStop.new("104","Shurling Drive and Gray Highway",["4"],[-83.614979,32.859722]),
  MaconStop.new("105","Shurling Drive and Clinton Road",["4-O"],[-83.617789,32.859735]),
  MaconStop.new("108","Clinton Road",["4-O"],[-83.615661,32.868055]),
  MaconStop.new("109","Clinton Road",["4-O"],[-83.614602,32.869431]),
  MaconStop.new("110","Clinton Road",["4-O"],[-83.613296,32.871178]),
  MaconStop.new("112","Gray Highway",["4"],[-83.612999,32.86402]),
  MaconStop.new("113","Gray Highway",["4"],[-83.613522,32.862293]),
  MaconStop.new("114","Gray Highway near McAffee Towers",["4"],[-83.616265,32.85777]),
  MaconStop.new("115","Clinton Road near McAffee Towers",["4"],[-83.618695,32.857116]),
  MaconStop.new("116","Clinton Road and Curry Place",["4"],[-83.619135,32.856165]),
  MaconStop.new("117","Clinton Road",["4"],[-83.619576,32.85503]),
  MaconStop.new("118","Clinton Road",["4"],[-83.620440,32.852642]),
  MaconStop.new("119","Clinton Road and Gray Highway",["4-O"],[-83.620867,32.851348]),
  MaconStop.new("120","Gray Highway",["4"],[-83.622024,32.850411]),
  MaconStop.new("121","Gray Highway",["4"],[-83.623353,32.849798]),
  MaconStop.new("122","2nd Street and Mulberry Street",["0"],[-83.628169,32.837823]),
  MaconStop.new("123","2nd and Cherry Street",["0"],[-83.629074,32.836563]),
  MaconStop.new("124","Mulberry Street and New Street",["0"],[-83.630926,32.839814]),
  MaconStop.new("125","Mulberry Street and 1st Street",["0"],[-83.629435,32.838839]),
  MaconStop.new("126","Spring Street",["0"],[-83.631964,32.841419]),
  MaconStop.new("127","Sping Street and Walnut Street",["0"],[-83.631412,32.842007]),
  MaconStop.new("128","Broadway and Oglethorpe Street",["3"],[-83.631333,32.828398]),
  MaconStop.new("129","Ogletorpe Street and 3rd Street",["3"],[-83.633160,32.828800]),
  MaconStop.new("130","Ogletorpe Street and 2nd Street",["3"],[-83.63514,32.829347]),
  MaconStop.new("131","2nd Street and Arch Street",["3","6"],[-83.634550,32.83004]),
  MaconStop.new("132","2nd Street and Hemlock Street",["0"],[-83.63343,32.831351]),
  MaconStop.new("133","2nd Street and Plum Street",["0"],[-83.63123,32.833964]),
  MaconStop.new("134","2nd and Pine Street",["0"],[-83.632343,32.832672]),
  MaconStop.new("135","2nd and Arch Street",["3","6"],[-83.634480,32.830175]),
  MaconStop.new("136","Broadway and Hazel Street",["12"],[-83.633784,32.825378]),
  MaconStop.new("137","Broadway and Hawthorne Street",["12"],[-83.63218,32.827309]),
  MaconStop.new("138","Broadway and Elm Street",["12"],[-83.635737,32.823093]),
  MaconStop.new("139","Broadway and Edgewood Street",["12"],[-83.636698,32.821928]),
  MaconStop.new("140","Houston Avenue",["12"],[-83.637914,32.820782]),
  MaconStop.new("141","Houston Avenue and Wood Street",["12"],[-83.638579,32.820307]),
  MaconStop.new("142","Houston Avenue and Giles Street",["12"],[-83.639597,32.819522]),
  MaconStop.new("143","Houston Avenue near Reid Street",["12"],[-83.64030,32.819015]),
  MaconStop.new("144","Houston Avenue and Jenkins Street",["12"],[-83.641221,32.818377]),
  MaconStop.new("145","Houston Avenue and Cynthia Avenue",["12"],[-83.642063,32.817771]),
  MaconStop.new("146","Houston Avenue and Whitehead Street",["12"],[-83.642866,32.817084]),
  MaconStop.new("147","Houston Avenue and Ell Street",["12"],[-83.64353,32.816445]),
  MaconStop.new("148","Houston Avenue and Ell Street Lane",["12"],[-83.644099,32.815681]),
  MaconStop.new("149","Houston Avenue and Eisenhower Parkway",["12"],[-83.64476,32.814028]),
  MaconStop.new("150","Houston Avenue and Central Avenue",["12"],[-83.645005,32.813357]),
  MaconStop.new("151","Houston Avenue and Second Street",["12"],[-83.645693,32.811984]),
  MaconStop.new("152","Houston Avenue and Nelson Street",["12"],[-83.646439,32.810463]),
  MaconStop.new("153","Houston Avenue and Cleavland Street",["12"],[-83.647362,32.808614]),
  MaconStop.new("154","Houston Avenue and Rutherford Avenue",["12"],[-83.647911,32.807551]),
  MaconStop.new("155","Houston Avenue and Lackey Drive",["12"],[-83.648598,32.806210]),
  MaconStop.new("156","Houston Avenue and Quinlan Drive",["12"],[-83.649207,32.804984]),
  MaconStop.new("157","Houston Avenue and Heard Avenue",["12"],[-83.650326,32.802776]),
  MaconStop.new("158","Houston Avenue near Villa Crest",["12"],[-83.650738,32.801958]),
  MaconStop.new("159","Houston Avenue and W. Greenada Terrace",["12"],[-83.651504,32.800437]),
  MaconStop.new("160","Houston Avenue and W. Ormand Terrace",["12"],[-83.652054,32.799309]),
  MaconStop.new("161","Houston Avenue and Villa Esta",["12"],[-83.652662,32.798049]),
  MaconStop.new("162","Houston Avenue and Lynmore Street",["12"],[-83.65309,32.797182]),
  MaconStop.new("164","Houston Avenue and Grady Street",["12"],[-83.655077,32.793142]),
  MaconStop.new("165","Houston Avenue and Fulton Street",["12"],[-83.655706,32.791817]),
  MaconStop.new("166","Houston Avenue and Buena Vista Avenue",["12"],[-83.657803,32.788188]),
  MaconStop.new("167","Houston Avenue and Green Street",["12"],[-83.658156,32.787386]),
  MaconStop.new("168","Houston Avenue and Chattam Street",["12"],[-83.658452,32.786682]),
  MaconStop.new("169","Chattam Street",["12"],[-83.657772,32.78668]),
  MaconStop.new("170","Chattam Street and Capital Avenue",["12"],[-83.65587,32.786655]),
  MaconStop.new("171","Houston Avenue amd Putnam Street",["12"],[-83.658998,32.782784]),
  MaconStop.new("173","Marion Avenue","12B",[-83.64669,32.789681]),
  MaconStop.new("174","Marion Avenue and Shi Place","12B",[-84.1666,-90.0]),
  MaconStop.new("175","Marion Avenue and Carmen Place","12B",[-83.64997,32.784366]),
  MaconStop.new("176","Marion Avenue and Shi Place","12B",[-83.6497,32.783340]),
  MaconStop.new("177","San Carlos Place",["12"],[-83.642902,32.790163]),
  MaconStop.new("178","San Carlos Drive and Melvin Place",["12"],[-83.642915,32.788018]),
  MaconStop.new("179","Albert Street and San Carlos Drive","12C",[-83.642990,32.785692]),
  MaconStop.new("180","Mead Road","12C",[-83.639788,32.78813]),
  MaconStop.new("181","Mead Road","12C",[-83.640300,32.790492]),
  MaconStop.new("182","2nd Street and Hawthorne Street",["6"],[-83.635789,32.82814]),
  MaconStop.new("183","2nd Street near Cynthia Avenue",["6"],[-83.644451,32.819241]),
  MaconStop.new("184","2nd Street and Anderson Street",["6"],[-83.642133,32.820868]),
  MaconStop.new("185","2nd Street and Wood Street",["6"],[-83.641182,32.821780]),
  MaconStop.new("186","2nd Street and Prince Street",["6"],[-83.640461,32.822693]),
  MaconStop.new("187","2nd Street and Edgewood Avenue",["6"],[-83.639601,32.823683]),
  MaconStop.new("188","2nd Street and Elm Street",["6"],[-83.638533,32.824809]),
  MaconStop.new("189","2nd Street and Ash Street",["6"],[-83.63744,32.826129]),
  MaconStop.new("190","2nd Street and Hazel Street",["6"],[-83.636626,32.827120]),
  MaconStop.new("191","2nd Street near Wyche Street",["6"],[-83.645354,32.818699]),
  MaconStop.new("192","2nd Street and Bowden Street",["6"],[-83.646142,32.818157]),
  MaconStop.new("193","2nd Street",["6"],[-83.646122,32.817611]),
  MaconStop.new("194","Ell Street",["6"],[-83.647144,32.816446]),
  MaconStop.new("195","2nd Street and Ell Street",["6"],[-83.64622,32.816461]),
  MaconStop.new("196","Ell Street and Felton Avenue",["6"],[-83.649475,32.816475]),
  MaconStop.new("197","A Street",["6"],[-83.652253,32.814927]),
  MaconStop.new("198","A Street and B Street",["6"],[-83.653775,32.81518]),
  MaconStop.new("199","A Street and Ell Street",["6"],[-83.654575,32.816515]),
  MaconStop.new("200","A Street",["6"],[-83.654861,32.814997]),
  MaconStop.new("201","Ell Street and Goodwin Street",["6"],[-83.657552,32.816567]),
  MaconStop.new("204","Pio Nono and Holley Street",["6-O"],[-83.662846,32.814990]),
  MaconStop.new("205","Ell Street and Adams Street",["6-O"],[-83.661105,32.81663]),
  MaconStop.new("206","Ell Street and Monroe Avenue",["6-O"],[-83.660275,32.816617]),
  MaconStop.new("208","Pio Nono Avenue near Home Depot",["6"],[-83.663041,32.813159]),
  MaconStop.new("209","Pio Nono Avenue and Hightower Road",["6-O"],[-83.663120,32.811347]),
  MaconStop.new("210","Pio Nono Avenue and  Rice Mill Road",["6"],[-83.662996,32.808735]),
  MaconStop.new("211","Pio Nono Avenue and Williamson Road",["6"],[-83.663104,32.806066]),
  MaconStop.new("212","Pio Nono Avenue and Newburg Avenue",["6"],[-83.663285,32.802578]),
  MaconStop.new("213","Pio Nono Avenue and Spencer Circle",["6"],[-83.665614,32.79863]),
  MaconStop.new("214","Pio Nono Avenue and Sherry Drive",["6"],[-83.664123,32.801159]),
  MaconStop.new("215","Pio Nono Avenue near Spencer Circle",["6"],[-83.665524,32.798378]),
  MaconStop.new("216","Pio Nono Avenue and South Plaza Shopping Center",["6"],[-83.667875,32.794529]),
  MaconStop.new("217","Pio Nono Avenue and South Plaza Shopping Center",["6"],[-83.667692,32.794255]),
  MaconStop.new("218","Pio Nono Avenue and Rocky Creek Road",["6"],[-83.668585,32.791433]),
  MaconStop.new("219","Rocky Creek Road",["6"],[-83.671678,32.79113]),
  MaconStop.new("220","Rocky Creek Road",["6"],[-83.672467,32.790415]),
  MaconStop.new("221","Rocky Creek Road",["6"],[-83.673930,32.788648]),
  MaconStop.new("222","Rocky Creek Road and South View Drive",["6"],[-83.678054,32.785488]),
  MaconStop.new("224","Rocky Creek Road and Bloomfield Drive",["6"],[-83.688296,32.785605]),
  MaconStop.new("225","Rocky Creek Road and Bloomfield Drive",["6"],[-83.688574,32.78547]),
  MaconStop.new("227","Rocky Creek Road and Thrasher Avenue",["6"],[-83.698513,32.786228]),
  MaconStop.new("228","Rocky Creek Road Bethesda Avenue",["6"],[-83.702895,32.786615]),
  MaconStop.new("229","Rocky Creek Plaza",["6"],[-83.706561,32.786979]),
  MaconStop.new("230","Debb Drive and Deborah Drive",["6"],[-83.710628,32.785630]),
  MaconStop.new("231","Debb Drive and Federica Place",["6"],[-83.709752,32.785607]),
  MaconStop.new("232","Debb Drive and Sterling Place",["6"],[-83.711551,32.785653]),
  MaconStop.new("233","Debb Drive",["6"],[-83.712428,32.785656]),
  MaconStop.new("234","Debb Drive",["6"],[-83.713696,32.785680]),
  MaconStop.new("235","Debb Drive",["6"],[-83.715057,32.785704]),
  MaconStop.new("236","Debb Drive",["6"],[-83.717642,32.785675]),
  MaconStop.new("237","Debb Drive",["6"],[-83.716816,32.784717]),
  MaconStop.new("238","Bloomfield Road and Anderson Drive",["6"],[-83.707685,32.788191]),
  MaconStop.new("239","Bloomfield Road and Wallace Drive",["6"],[-83.707679,32.789419]),
  MaconStop.new("240","Bloomfield Road and Robinhood Road",["6"],[-83.707585,32.794154]),
  MaconStop.new("241","Bloomfield Road and Greenwod Road",["6"],[-83.707568,32.793024]),
  MaconStop.new("242","Bloomfield Road",["6"],[-83.707533,32.795323]),
  MaconStop.new("243","Bloomfield Road and Pine Forest Road",["6"],[-83.707449,32.798227]),
  MaconStop.new("244","1st Street and Walnut Street",["5"],[-83.628192,32.840139]),
  MaconStop.new("245","Riverside Drive and Spring Street",["5"],[-83.630810,32.843673]),
  MaconStop.new("246","Riverside Drive near Spring Street",["5"],[-83.630569,32.843326]),
  MaconStop.new("247","Riverside Drive near Franklin Street",["5"],[-83.631612,32.84417]),
  MaconStop.new("248","Riverside Drive and Franklin Street",["5"],[-83.632021,32.844178]),
  MaconStop.new("249","Riverside Drive and Jones Street",["5"],[-83.632703,32.844808]),
  MaconStop.new("250","Riverside Drive near Orange Street",["5"],[-83.634233,32.84591]),
  MaconStop.new("251","Riverside Drive and College Street",["5"],[-83.635834,32.846609]),
  MaconStop.new("252","Riverside Drive and Madison Street",["5"],[-83.637436,32.847284]),
  MaconStop.new("253","Madison Street and Walnut Street",["5"],[-83.63823,32.845519]),
  MaconStop.new("254","Walnut Street",["5"],[-83.639725,32.846056]),
  MaconStop.new("255","Walnut Street",["5"],[-83.640159,32.846324]),
  MaconStop.new("256","Walnut Street near Eastern side of I-75",["5"],[-83.641591,32.847084]),
  MaconStop.new("257","Walnut Street near Western side of I-75",["5"],[-83.642618,32.847318]),
  MaconStop.new("258","Walnut Street and Moughan Street",["5"],[-83.646417,32.848104]),
  MaconStop.new("259","Walnut Street and Ward Street",["5"],[-83.647930,32.848290]),
  MaconStop.new("260","Walnut Street and Giant Avenue",["5"],[-83.647135,32.848238]),
  MaconStop.new("261","Pierce Avenue near Riverside Drive",["5"],[-83.662347,32.872369]),
  MaconStop.new("262","Riverside Drive near Wimbish Road",["5"],[-83.672875,32.885469]),
  MaconStop.new("263","Riverside Drive near Northside Drive",["5"],[-83.677070,32.890632]),
  MaconStop.new("264","Ward Street and 3rd Avenue",["5"],[-83.648521,32.84685]),
  MaconStop.new("265","Ward Street and Forest Avenue",["5"],[-83.649606,32.847210]),
  MaconStop.new("266","3rd Avenue and Moughan Street",["5-O"],[-83.647020,32.846441]),
  MaconStop.new("267","3rd Avenue and Pursley Street",["5-O"],[-83.645936,32.846014]),
  MaconStop.new("268","3rd Avenue and 4th Street",["5-O"],[-83.643538,32.845086]),
  MaconStop.new("269","3rd Avenue near Empire Street",["5-O"],[-83.645332,32.845623]),
  MaconStop.new("270","4th Street and 2nd Avenue",["5-O"],[-83.644151,32.84392]),
  MaconStop.new("271","2nd Avenue",["5-O"],[-83.645465,32.844301]),
  MaconStop.new("272","2nd Avenue and Pursley Street",["5-O"],[-83.646800,32.844694]),
  MaconStop.new("273","Ward Street and 2nd Street",["5-O"],[-83.64909,32.845462]),
  MaconStop.new("274","Sycamore Street and Walnut Street",["5"],[-83.652817,32.848405]),
  MaconStop.new("275","Clayton Street and Rogers Avenue",["5"],[-83.655258,32.848962]),
  MaconStop.new("276","Rogers Avenue",["5"],[-83.65525,32.849897]),
  MaconStop.new("277","Rogers Avenue and Neal Avenue",["5"],[-83.655183,32.851166]),
  MaconStop.new("278","Rogers Avenue and Rogers Place",["5"],[-83.654586,32.853139]),
  MaconStop.new("279","Rogers Avenue and Ingleside Avenue",["5"],[-83.654353,32.853756]),
  MaconStop.new("280","Ingleside Avenue",["5-O"],[-83.64730,32.854838]),
  MaconStop.new("281","Ingleside Avenue and Riverside Drive",["5-O"],[-83.645085,32.855693]),
  MaconStop.new("282","Riverside Drive near Bibb Co Vocational Complex",["5-O"],[-83.643859,32.854453]),
  MaconStop.new("283","Baxter Avenue and North Brook",["5-O"],[-83.643306,32.852599]),
  MaconStop.new("284","Baxter Avenue and Mallory Drive",["5-O"],[-83.644562,32.852304]),
  MaconStop.new("285","Forest Avenue",["5-O"],[-83.646547,32.852295]),
  MaconStop.new("286","Forest Avenue and Sherman Avenue",["5-O"],[-83.648054,32.849952]),
  MaconStop.new("287","Forest Avenue and Walnut Street",["5-O"],[-83.648983,32.848443]),
  MaconStop.new("288","Pierce Avenue",["5"],[-83.66215,32.86057]),
  MaconStop.new("289","Pierce Avenue and Old Horton Road",["5"],[-83.661556,32.865111]),
  MaconStop.new("290","Pierce Avenue",["5"],[-83.662265,32.867488]),
  MaconStop.new("291","Pierce Avenue and Sheffield Road",["5"],[-83.662394,32.871101]),
  MaconStop.new("292","Riverside Drive and Burrus Road",["5"],[-83.663866,32.874867]),
  MaconStop.new("293","Riverside Drive and Lee Road",["5"],[-83.666265,32.877650]),
  MaconStop.new("294","Riverside Drive",["5"],[-83.667055,32.878872]),
  MaconStop.new("295","Riverside Drive near Thornwood Drive",["5"],[-83.668836,32.880895]),
  MaconStop.new("296","Riverside Drive near Wimbish Road",["5"],[-83.673164,32.886164]),
  MaconStop.new("297","Riverside Drive",["5"],[-83.674401,32.887598]),
  MaconStop.new("298","Riverside Drive near Northside Drive",["5"],[-83.676874,32.890653]),
  MaconStop.new("299","Northside Drive near North Ingle Place",["5-O"],[-83.677744,32.890930]),
  MaconStop.new("300","Northside Drive",["5-O"],[-83.679855,32.891841]),
  MaconStop.new("301","Northside Drive and Holiday Drive North",["5-O"],[-83.687307,32.895105]),
  MaconStop.new("302","Northside Drive and Tom Hill Sr BLVD",["5-O"],[-83.690188,32.896503]),
  MaconStop.new("303","Tom Hill Sr and Riverside Drive",["5"],[-83.686803,32.900901]),
  MaconStop.new("304","Riverside Drive and Holiday Drive",["5"],[-83.685785,32.900246]),
  MaconStop.new("305","Riverside Drive",["5"],[-83.684519,32.899527]),
  MaconStop.new("306","Riverside Drive near SS Office",["5"],[-83.683776,32.898768]),
  MaconStop.new("307","Riverside Drive",["5"],[-83.67915,32.893267]),
  MaconStop.new("308","Ingleside Avenue and Corbin Avenue",["5"],[-83.657490,32.853733]),
  MaconStop.new("309","Ingleside Avenue",["5"],[-83.65653,32.853747]),
  MaconStop.new("310","Ingleside Avenue and Bufford Place",["5"],[-83.660428,32.853763]),
  MaconStop.new("311","Ingleside Avenue and Pierce Avenue",["5"],[-83.662436,32.853807]),
  MaconStop.new("312","1st Street and Plum Street",["9"],[-83.63267,32.834914]),
  MaconStop.new("313","1st Street and Pine Street",["9"],[-83.633877,32.833598]),
  MaconStop.new("314","2nd Street and Pine Street",["12"],[-83.632537,32.83283]),
  MaconStop.new("315","1st Street and Hemlock Street",["9"],[-83.635008,32.832283]),
  MaconStop.new("316","1st Street and Hemlock Street",["9"],[-83.635053,32.832097]),
  MaconStop.new("317","1st Street and Arch Street",["9"],[-83.636052,32.830966]),
  MaconStop.new("318","1st Street and Arch Street",["9"],[-83.636162,32.831004]),
  MaconStop.new("319","Telfair Street and Hawthorne Street",["9"],[-83.63945,32.828730]),
  MaconStop.new("320","Telfair Street near Hazel Street",["9"],[-83.639745,32.828638]),
  MaconStop.new("321","Telfair Street and Ash Street",["9"],[-83.640433,32.827692]),
  MaconStop.new("322","Telfair Street and Elm Street",["9"],[-83.641409,32.826543]),
  MaconStop.new("323","Telfair Street near RR Crossing",["9"],[-83.642097,32.825821]),
  MaconStop.new("324","Telfair Street and Prince Street",["9"],[-83.643383,32.824338]),
  MaconStop.new("325","Telfair Street near Pebble Street",["9"],[-83.643739,32.823744]),
  MaconStop.new("326","Jeff Davis Street and Curd Street",["9"],[-83.64524,32.822486]),
  MaconStop.new("327","Jeff Davis Street and Williams Street",["9"],[-83.646107,32.821857]),
  MaconStop.new("328","Jeff Davis Street and Emory Street",["9"],[-83.646659,32.82146]),
  MaconStop.new("329","Jeff Davis Street near Harold Street",["9"],[-83.647566,32.820802]),
  MaconStop.new("330","Jeff Davis Street and Alley",["9"],[-83.648317,32.820233]),
  MaconStop.new("331","Felton Avenue near Jeff Davis Street",["9"],[-83.649319,32.820261]),
  MaconStop.new("332","Felton Avenue",["9"],[-83.649316,32.820809]),
  MaconStop.new("333","Felton Avenue",["9"],[-83.64932,32.821321]),
  MaconStop.new("334","Felton Avenue",["9"],[-83.649275,32.823085]),
  MaconStop.new("335","Felton Avenue",["9"],[-83.649309,32.822024]),
  MaconStop.new("336","Felton Avenue and Plant Street",["9"],[-83.649213,32.824038]),
  MaconStop.new("337","Plant Street and Little Richard Penniman",["9"],[-83.651079,32.825893]),
  MaconStop.new("338","Little Richard Penniman",["9"],[-83.651602,32.825752]),
  MaconStop.new("339","Little Richard Penniman",["9"],[-83.652548,32.825768]),
  MaconStop.new("340","Little Richard Penniman and Stadium Drive",["9"],[-83.653479,32.825772]),
  MaconStop.new("341","Mercer University BLVDand Canton Road",["9"],[-83.654044,32.825726]),
  MaconStop.new("342","Mercer University BLVD",["9"],[-83.659365,32.825796]),
  MaconStop.new("343","Mercer University BLVD and Madden Avenue",["9"],[-83.660438,32.825824]),
  MaconStop.new("344","Mercer University Blvd near Pio Nono Avenue",["9"],[-83.661518,32.825806]),
  MaconStop.new("345","Pio Nono Avenue near Mercer University Blvd",["9"],[-83.662724,32.825599]),
  MaconStop.new("346","Pio Nono Avenue",["9"],[-83.662680,32.824560]),
  MaconStop.new("347","Pio Nono Avenue near Vining Circle",["9"],[-83.662775,32.823420]),
  MaconStop.new("348","Pio Nono Avenue and Stephens Street",["9"],[-83.662688,32.822090]),
  MaconStop.new("349","Pio Nono Avenue and Aline Street",["9"],[-83.662853,32.820814]),
  MaconStop.new("350","Anthony Road and Cedar Avenue",["9-O"],[-83.664494,32.820209]),
  MaconStop.new("351","Anthony Road and Anthony Terrace",["9-O"],[-83.667801,32.820196]),
  MaconStop.new("353","Eisnhower Parkway and Anthony Terrace",["9"],[-83.667611,32.814610]),
  MaconStop.new("354","Eisenhower Parkyway near Pio Nono Avenue",["9"],[-83.663392,32.814487]),
  MaconStop.new("355","Eisenhower Parkway",["9"],[-83.669815,32.814672]),
  MaconStop.new("356","Eisenhower Parkway and Key Street",["9"],[-83.675295,32.814747]),
  MaconStop.new("357","Eisenhower Parkway and Heron Street",["9"],[-83.679545,32.814870]),
  MaconStop.new("358","Eisenhower Parkway and Oglesby Place",["9"],[-83.685086,32.815344]),
  MaconStop.new("359","Eisenhower Parkway near Macon Mall",["9"],[-83.690438,32.815630]),
  MaconStop.new("360","Eisenhower Parkway near Macon Mall",["9"],[-83.691257,32.815474]),
  MaconStop.new("361","Eisenhower Parkway",["9"],[-83.685594,32.815183]),
  MaconStop.new("362","Eisenhower Parkway and Bloomfield Road",["9-I"],[-83.698896,32.815831]),
  MaconStop.new("363","Bloomfield Road",["9"],[-83.70001,32.81383]),
  MaconStop.new("364","Bloomfield Road and Jackson Street",["9-O"],[-83.701028,32.812872]),
  MaconStop.new("365","Bloomfield Road and Walker Avenue",["9-O"],[-83.702152,32.811869]),
  MaconStop.new("366","Bloomfield Road",["9-O"],[-83.703896,32.810258]),
  MaconStop.new("367","Bloomfield Road",["9-O"],[-83.704944,32.809343]),
  MaconStop.new("368","Bloomfield Road",["9-O"],[-83.70650,32.807529]),
  MaconStop.new("369","Bloomfield Road and Chambers Road",["9-O"],[-83.707496,32.80637]),
  MaconStop.new("375","Chambers Road",["9-O"],[-83.719864,32.806496]),
  MaconStop.new("376","Macon State College",["9"],[-83.729056,32.808785]),
  MaconStop.new("377","Oglethorpe Street and Second Street",["3"],[-83.637743,32.830036]),
  MaconStop.new("378","Oglethorpe Street and Lee Street",["3"],[-83.639642,32.830691]),
  MaconStop.new("379","Oglethorpe Street and Calhoun Street",["3"],[-83.641340,32.831737]),
  MaconStop.new("380","Oglethorpe Street and Appleton Street",["3"],[-83.642811,32.832590]),
  MaconStop.new("381","College Street near Tatnall Square Park",["3"],[-83.645021,32.833559]),
  MaconStop.new("382","Coleman Avenue and Adams Street",["3"],[-83.649000,32.832808]),
  MaconStop.new("383","Montpelier Avenue near I-75",["3"],[-83.653109,32.83279]),
  MaconStop.new("384","Montpelier Avenue and Duncan Avenue",["3"],[-83.654396,32.832766]),
  MaconStop.new("385","Montpelier Avenue and Oakland Avenue",["3"],[-83.656119,32.832693]),
  MaconStop.new("386","Montpelier Avenue and Pio Nono Avenue",["3"],[-83.66200,32.832382]),
  MaconStop.new("387","Montpelier Avenue and Courtland Street",["3"],[-83.664095,32.831735]),
  MaconStop.new("388","Montpelier Avenue near Old Miller School",["3"],[-83.659319,32.832674]),
  MaconStop.new("389","Montpelier Avenue and Patterson Street",["3"],[-83.660606,32.832744]),
  MaconStop.new("390","Montpelier Avenue and Blossom Street",["3"],[-83.666085,32.831183]),
  MaconStop.new("391","Montpelier Avenue and Vinton Avenue",["3"],[-83.667204,32.830916]),
  MaconStop.new("392","Montpelier Avenue and Poppy Avenue",["3"],[-83.666882,32.830883]),
  MaconStop.new("393","Montpelier Avenue and Brebtwood Avenue",["3"],[-83.668398,32.830585]),
  MaconStop.new("394","Montpelier Avenue",["3"],[-83.665137,32.831435]),
  MaconStop.new("395","Montpelier Avenue",["3"],[-83.669764,32.830175]),
  MaconStop.new("396","Montpelier Avenue and Buena Vista",["3"],[-83.671053,32.82982]),
  MaconStop.new("397","Montpelier Avenue and Helon Street",["3"],[-83.673272,32.82908]),
  MaconStop.new("398","Montpelier Avenue and Bailey Street",["3"],[-83.674278,32.828611]),
  MaconStop.new("399","Montpelier Avenue",["3"],[-83.675284,32.827975]),
  MaconStop.new("400","Montpelier Avenue and Mercer University Drive",["3"],[-83.676977,32.82655]),
  MaconStop.new("401","Mercer University Drive and Well Worth Avenue",["3"],[-83.679655,32.82495]),
  MaconStop.new("402","Mercer University Drive and Anthony Road",["3"],[-83.68164,32.823845]),
  MaconStop.new("403","Anthony Road near Mercer University Drive",["3"],[-83.681574,32.823621]),
  MaconStop.new("404","Anthony Road and Swan Drive",["3"],[-83.680159,32.822768]),
  MaconStop.new("405","Swan Drive",["3"],[-83.680711,32.822099]),
  MaconStop.new("406","Swan Drive",["3"],[-83.680943,32.821317]),
  MaconStop.new("407","Swan Drive",["3"],[-83.680040,32.820258]),
  MaconStop.new("408","Swan Drive",["3"],[-83.680083,32.819331]),
  MaconStop.new("409","Wren Avenue",["3"],[-83.680963,32.817689]),
  MaconStop.new("410","Wren Avenue",["3"],[-83.679600,32.817651]),
  MaconStop.new("411","Wren Avenue",["3"],[-83.67925,32.817746]),
  MaconStop.new("412","Wren Avenue",["3"],[-83.680856,32.81647]),
  MaconStop.new("413","Wren Avenue",["3"],[-83.677366,32.817802]),
  MaconStop.new("414","Heron Street",["3"],[-83.679477,32.815989]),
  MaconStop.new("415","Wren Avenue",["3"],[-83.676700,32.818327]),
  MaconStop.new("416","Wren Avenue",["3"],[-83.676371,32.819716]),
  MaconStop.new("417","Key Street",["3"],[-83.674608,32.820173]),
  MaconStop.new("418","Key Street",["3"],[-83.675398,32.817571]),
  MaconStop.new("419","Mercer University Drive and Selma Street",["3"],[-83.682825,32.823274]),
  MaconStop.new("420","Mercer University Drive and Oglesby Place",["3"],[-83.685142,32.821956]),
  MaconStop.new("421","Mercer University Drive and Edna Place",["3"],[-83.689274,32.820805]),
  MaconStop.new("422","Mercer University Drive near the Mall",["3"],[-83.69344,32.820453]),
  MaconStop.new("423","Mercer University Drive and Northwoods Drive",["3"],[-83.699486,32.822570]),
  MaconStop.new("424","Mercer University Drive",["3"],[-83.702150,32.823635]),
  MaconStop.new("425","Mercer University Drive and Bloomfield Road",["3"],[-83.695784,32.82105]),
  MaconStop.new("426","Mercer University Drive",["3"],[-83.696861,32.82150]),
  MaconStop.new("427","Mercer Univeristy Drive",["3"],[-83.705891,32.824959]),
  MaconStop.new("428","Mercer University Drive",["3"],[-83.706761,32.825090]),
  MaconStop.new("429","Mercer University Drive",["3"],[-83.708539,32.825432]),
  MaconStop.new("430","Mercer University Drive and Log Cabin Drive",["3"],[-83.709446,32.825659]),
  MaconStop.new("431","Mercer University Drive and Columbus Road",["3"],[-83.714139,32.825932]),
  MaconStop.new("432","Mercer University Drive and West Drive",["3"],[-83.71652,32.826644]),
  MaconStop.new("433","Mercer University and Ebenezer Church Road",["3"],[-83.71657,32.826484]),
  MaconStop.new("434","Mercer University Drive near Vallie Drive",["3"],[-83.711434,32.825635]),
  MaconStop.new("435","Mercer University Drive and West Oak Court",["3"],[-83.720170,32.827504]),
  MaconStop.new("436","Mercer University Drive and West Oak Drive",["3"],[-83.721755,32.828437]),
  MaconStop.new("437","Mercer University Drive and Emory Greene Drive",["3"],[-83.727173,32.831461]),
  MaconStop.new("438","Mercer University Drive and Macon West Drive",["3"],[-83.725283,32.83083]),
  MaconStop.new("439","Mercer University Drive and Woodfield Drive",["3"],[-83.723132,32.829465]),
  MaconStop.new("440","Mercer University Drive and Tucker Valley Road",["3"],[-83.731635,32.832787]),
  MaconStop.new("441","Mercer University Drive near I-475",["3"],[-83.735795,32.833680]),
  MaconStop.new("442","Mercer University Drive near McManus Drive",["3"],[-83.737745,32.833783]),
  MaconStop.new("443","Mercer University Drive and Knight Road",["3"],[-83.740962,32.833970]),
  MaconStop.new("444","Mercer University Drive near Food Lion",["3"],[-83.743347,32.834026]),
  MaconStop.new("445","Vineville Avenue and Craft Street",["1"],[-83.646861,32.841141]),
  MaconStop.new("447","Washington Street and College Street",["1-I"],[-83.638700,32.83918]),
  MaconStop.new("448","Vineville Avenue and Holt Avenue",["1"],[-83.64999,32.84202]),
  MaconStop.new("449","Vineville Avenue and Ward Street",["1"],[-83.650675,32.842432]),
  MaconStop.new("450","Vineville Avenue",["1"],[-83.652060,32.843317]),
  MaconStop.new("451","Vineville Avenue and Lamar Street",["1"],[-83.653294,32.844138]),
  MaconStop.new("452","Vineville Avenue and Culver Street",["1"],[-83.654559,32.844883]),
  MaconStop.new("453","Vineville Avenue and Rogers Avenue",["1"],[-83.655552,32.845512]),
  MaconStop.new("454","Vineville Avenue and Corbin Avenue",["1"],[-83.657300,32.846233]),
  MaconStop.new("455","Vineville Avenue and Calloway Drive",["1"],[-83.658222,32.846301]),
  MaconStop.new("456","Vinevile Avenue and Buford Place",["1"],[-83.659400,32.846255]),
  MaconStop.new("457","Vineville Avenue and Hines Place",["1"],[-83.660700,32.846196]),
  MaconStop.new("458","Vineville Avenue and Stonewall Place",["1"],[-83.663994,32.846031]),
  MaconStop.new("459","Vineville Avenue and Holmes Avenue",["1"],[-83.665036,32.846073]),
  MaconStop.new("460","Vineville Avenue and Desoto Place",["1"],[-83.667204,32.846365]),
  MaconStop.new("461","Vineville Avenue @ Blind Academy",["1"],[-83.669157,32.847155]),
  MaconStop.new("462","Vineville Avenue and Kenmore Place",["1"],[-83.671446,32.848177]),
  MaconStop.new("463","Vineville Avenue and Speer Street",["1"],[-83.672181,32.848499]),
  MaconStop.new("464","Vineville Avenue and Vista Drive",["1"],[-83.67335,32.849463]),
  MaconStop.new("465","Vineville Avenue and Hartley Avenue",["1"],[-83.674443,32.850480]),
  MaconStop.new("466","Vineville Avenue and Marshall Avenue",["1"],[-83.675553,32.851426]),
  MaconStop.new("467","Vineville Avenue",["1-O"],[-83.67664,32.852372]),
  MaconStop.new("468","Vineville Avenue",["1-O"],[-83.678046,32.853604]),
  MaconStop.new("469","Vineville Avenue near Brookdale Avenue",["1-O"],[-83.678716,32.854175]),
  MaconStop.new("470","Vineville Avenue",["1-O"],[-83.681125,32.856405]),
  MaconStop.new("471","Vineville Avenue and Prentice Place",["1-O"],[-83.681690,32.856958]),
  MaconStop.new("472","Vineville Avenue and Auburn Avenue",["1-O"],[-83.68273,32.857957]),
  MaconStop.new("473","Vineville Avenue and Belvedere",["1-O"],[-83.683198,32.858403]),
  MaconStop.new("474","Vineville Avenue and Albermarle",["1-O"],[-83.683994,32.859188]),
  MaconStop.new("475","Ridge Avenue and Ingleside Avenue",["1"],[-83.678642,32.856182]),
  MaconStop.new("476","Vineville Avenue and Riverdale Drive",["1-O"],[-83.68485,32.859973]),
  MaconStop.new("477","Ridge Avenue",["1"],[-83.677701,32.855166]),
  MaconStop.new("479","Ridge Avenue and Auburn Avenue",["1"],[-83.681448,32.859018]),
  MaconStop.new("480","Ridge Avenue and Belvedere",["1"],[-83.681992,32.859464]),
  MaconStop.new("481","Ridge Avenue and Albermarle Place",["1"],[-83.682894,32.86012]),
  MaconStop.new("482","Ridge Avenue and Riverdale Drive",["1"],[-83.683964,32.86084]),
  MaconStop.new("483","Ridge Avenue and Merritt Avenue",["1"],[-83.68488,32.861589]),
  MaconStop.new("484","Ridge Avenue and Roycrest Drive",["1"],[-83.686816,32.86285]),
  MaconStop.new("485","Vineville Avenue and West Ridge Circle",["1-O"],[-83.691250,32.864261]),
  MaconStop.new("486","Vineville Avenue near Charter Hospital",["1-O"],[-83.694335,32.866049]),
  MaconStop.new("487","Vineville Avenue near Charter Hospital",["1-O"],[-83.694250,32.866227]),
  MaconStop.new("488","New Street @ The Medical Center",["2"],[-83.635363,32.834665]),
  MaconStop.new("489","Pine Street and Spring Street",["2"],[-83.636762,32.835426]),
  MaconStop.new("490","Cotton Avenue and College Street",["2"],[-83.640358,32.836197]),
  MaconStop.new("491","Oglethrope Street and Tatnall Street",["2-O"],[-83.645627,32.834263]),
  MaconStop.new("492","College Street near RR under pass",["2-O"],[-83.643545,32.83476]),
  MaconStop.new("493","Oglethorpre Street and Adams Street",["2"],[-83.647073,32.835096]),
  MaconStop.new("494","Adams Street",["2"],[-83.648040,32.83400]),
  MaconStop.new("495","Adams Street",["2"],[-83.648771,32.833084]),
  MaconStop.new("496","Coleman Avenue and Linden Avenue",["2"],[-83.649927,32.833337]),
  MaconStop.new("497","Coleman Avenue and Johnson Avenue",["2"],[-83.650963,32.833954]),
  MaconStop.new("498","Coleman Avenue and I-75",["2"],[-83.651645,32.834652]),
  MaconStop.new("499","Coleman Avenue and Duncan Avenue",["2"],[-83.652327,32.835317]),
  MaconStop.new("500","Napier Avenue and Vine Street",["2"],[-83.654010,32.835903]),
  MaconStop.new("501","Napier Avenue and Vine Street",["2"],[-83.655206,32.835924]),
  MaconStop.new("502","Napier Avenue and Blackmon Avenue",["2"],[-83.656285,32.835929]),
  MaconStop.new("503","Naper Avenue and Hendley Street",["2"],[-83.657775,32.835985]),
  MaconStop.new("504","Napier Avenue and Birch Street",["2"],[-83.659285,32.83600]),
  MaconStop.new("505","Napier Avenue and Patterson Street",["2"],[-83.660755,32.836046]),
  MaconStop.new("506","Napier Avenue and Pio Nono Avenue",["2"],[-83.662324,32.836102]),
  MaconStop.new("507","Napier Avenue and Courtland Street",["2"],[-83.66395,32.836109]),
  MaconStop.new("508","Napier Avenue and Hillyer Avenue",["2"],[-83.665539,32.836181]),
  MaconStop.new("509","Napier Avenue and Winton Avenue",["2"],[-83.667030,32.836171]),
  MaconStop.new("510","Napier Avenue",["2"],[-83.667736,32.836174]),
  MaconStop.new("511","Napier Avenue and Inverness Street",["2"],[-83.669006,32.836874]),
  MaconStop.new("512","Napier Avenue and Bartlett Street",["2"],[-83.670556,32.836897]),
  MaconStop.new("513","Napier Avenue and Bartlett Street",["2"],[-83.670967,32.83686]),
  MaconStop.new("514","Napier Avenue and Ernest Street",["2"],[-83.672418,32.836904]),
  MaconStop.new("515","Napier Avenue and Bailey Avenue",["2"],[-83.674752,32.836980]),
  MaconStop.new("516","Napier Avenue",["2"],[-83.675964,32.837646]),
  MaconStop.new("517","Napier Avenue and Radio Drive",["2"],[-83.676688,32.837964]),
  MaconStop.new("518","Napier Avenue",["2"],[-83.681479,32.840300]),
  MaconStop.new("519","Napier Avenue and Burton Avenue",["2"],[-83.678998,32.838552]),
  MaconStop.new("520","Napier Avenue",["2"],[-83.682556,32.840586]),
  MaconStop.new("521","Napier Avenue and Carlisle Avenue",["2"],[-83.683027,32.840555]),
  MaconStop.new("522","Napier Avenue and Cypress",["2"],[-83.685614,32.840945]),
  MaconStop.new("523","Napier Avenue and Log Cabin",["2"],[-83.687119,32.8419]),
  MaconStop.new("524","Napier Avenue and Log Cabin",["2"],[-83.68725,32.841829]),
  MaconStop.new("525","Log Cabin Road and Scotland Avenue",["2"],[-83.68991,32.839935]),
  MaconStop.new("526","Log Cabin Road and James Road",["2"],[-83.691410,32.838931]),
  MaconStop.new("527","Log Cabin Road and Sherbrook",["2"],[-83.692940,32.838854]),
  MaconStop.new("528","Log Cabin Road and Pike Street",["2"],[-83.695156,32.838829]),
  MaconStop.new("529","Log Cabin Road and Hollingsworth Road",["2"],[-83.700997,32.835524]),
  MaconStop.new("530","Log Cabin Road",["2"],[-83.687729,32.841434]),
  MaconStop.new("531","Log Cabin Road",["2"],[-83.699444,32.836412]),
  MaconStop.new("532","Hollingsworth Road",["2"],[-83.700263,32.837292]),
  MaconStop.new("533","Hollingsworth Road and Wolf Creek Drive",["2"],[-83.699745,32.838747]),
  MaconStop.new("534","Hollingsworth Road",["2"],[-83.699245,32.840567]),
  MaconStop.new("535","Hollingsworth Road",["2"],[-83.697963,32.842019]),
  MaconStop.new("536","Hollingsworth Road",["2"],[-83.69695,32.843097]),
  MaconStop.new("537","Hollingsworth Road and Mumford Road",["2"],[-83.696259,32.847120]),
  MaconStop.new("538","Mumford Road and Case Street",["2"],[-83.692198,32.84710]),
  MaconStop.new("539","Mumford Road",["2"],[-83.689383,32.847062]),
  MaconStop.new("540","Napier Avenue and Mumford Road",["2"],[-83.688099,32.847057]),
  MaconStop.new("541","Napier Avenue near McKenzie Drive",["2"],[-83.687916,32.849174]),
  MaconStop.new("542","Napier Avenue and Brookdale Avenue",["2"],[-83.687838,32.852876]),
  MaconStop.new("543","Napier Avenue and Fairmont Avenue",["2"],[-83.687787,32.855301]),
  MaconStop.new("545","Forsyth Road near Napier Avenue",["2B"],[-83.69943,32.869088]),
  MaconStop.new("546","Forsyth Road",["2B"],[-83.701463,32.870179]),
  MaconStop.new("547","Forsyth Road near Idle Hour",["2B"],[-83.707176,32.87317]),
  MaconStop.new("548","Forsyth Road near Country Club Road",["2B"],[-83.70601,32.872476]),
  MaconStop.new("549","Forsyth Road near Kroger Shopping Center",["2B"],[-83.709813,32.874462]),
  MaconStop.new("550","Forsyth Road near Kroger Shopping Center",["2B"],[-83.708342,32.873794]),
  MaconStop.new("551","Forsyth Road near Kroger Shopping Center",["2B"],[-83.709603,32.87446]),
  MaconStop.new("552","Forsyth Road and Tucker Road",["2B"],[-83.710807,32.87499]),
  MaconStop.new("553","Forsyth Road and Wesleyan Woods Drive",["2B"],[-83.715779,32.876844]),
  MaconStop.new("554","Forsyth Road and Wesleyan Woods Drive",["2B"],[-83.716048,32.876748]),
  MaconStop.new("555","Forsyth Road near Brittany Drive",["2B"],[-83.722990,32.879473]),
  MaconStop.new("556","Forsyth Road and Zebulon Road",["2B"],[-83.724787,32.880207]),
  MaconStop.new("557","Riverside Drive near SS Administration",["5"],[-83.682623,32.897388]),
  MaconStop.new("558","Hardeman and Monroe St Lane",["1-I"],[-83.641545,32.839983]),
  MaconStop.new("559","Hardeman and Franks Lane",["1"],[-83.643928,32.840642]),
  MaconStop.new("560","Vineville and Pierce Avenue",["1"],[-83.662378,32.846135]),
  MaconStop.new("561","Vineville and Florida Street",["1"],[-83.666116,32.84621]),
  MaconStop.new("562","Madison Street and Stewarts Lane",["5-O"],[-83.638951,32.843710]),
  MaconStop.new("563","Madison Street",["5-O"],[-83.639488,32.842549]),
  MaconStop.new("564","Jefferson Street and Madison Street",["5-O"],[-83.640026,32.841320]),
  MaconStop.new("565","Sheraton Drive near Arkwright Road",["13-O"],[-83.688863,32.90633]),
  MaconStop.new("566","Sheraton Drive",["13-O"],[-83.690843,32.908248]),
  MaconStop.new("567","Sheraton Drive Near Apartments",["13-O"],[-83.695285,32.911197]),
  MaconStop.new("568","Sheraton Drive",["13-O"],[-83.698853,32.913942]),
  MaconStop.new("569","",["13-O"],[-83.702182,32.916841]),
  MaconStop.new("570","Sheraton Drive Near Apartments",["13"],[-83.702182,32.916841]),
  MaconStop.new("571","Sheraton Drive at Groomes Transportation",["13-O"],[-83.703900,32.918191]),
  MaconStop.new("572","Sheraton Drive and Sheraton Blvd",["13-O"],[-83.705222,32.919158]),
  MaconStop.new("573","Sheraton Drive and Gateway Drive",["13-O"],[-83.70912,32.924791]),
  MaconStop.new("574","Sheraton Drive and Sheraton Blvd North",["13-O"],[-83.707150,32.920799]),
  MaconStop.new("575","Sheraton Drive and Gateway Drive",["13"],[-83.709094,32.924813]),
  MaconStop.new("576","Sheraton Drive and Riverside Drive",["13-O"],[-83.711247,32.924194]),
  MaconStop.new("577","Riverside Drive and Bass Road",["13-O"],[-83.717500,32.936662]),
  MaconStop.new("578","Riverside Drive and Hall Road",["13"],[-83.70566,32.915220]),
  MaconStop.new("579","Riverside Drive near Access Road",["13"],[-83.699347,32.910944]),
  MaconStop.new("580","Riverside Drive and Sue Drive",["13"],[-83.693979,32.907342]),
  MaconStop.new("581","Riverside Drive and North Crest Blvd",["13"],[-83.690806,32.905226]),
  MaconStop.new("582","Vineville Avenue near Country Club Road",["2"],[-83.704975,32.871997]),
  MaconStop.new("583","Vineville Avenue near Idle Wild Road",["2"],[-83.702711,32.870839]),
  MaconStop.new("584","Napier Avenue and Canyon Road",["2"],[-83.698374,32.865671]),
  MaconStop.new("585","Napier Avenue and Park Street",["2"],[-83.69207,32.859069]),
  MaconStop.new("586","Napier Avenue near Apartments",["2"],[-83.689110,32.857483]),
  MaconStop.new("587","Napier Avenue and Atlantic Avenue",["2"],[-83.687836,32.850410]),
  MaconStop.new("588","Mumford Road and Lawton Road",["2"],[-83.69380,32.847112]),
  MaconStop.new("589","Hollingsworth Road",["2"],[-83.696209,32.845673]),
  MaconStop.new("590","Good Will Center",["9"],[-83.731704,32.803532]),
  MaconStop.new("592","Macon Mall",["9-O"],[-83.694350,32.817293]),
  MaconStop.new("593","Anthony Terrace",["9-O"],[-83.667757,32.817592]),
  MaconStop.new("594","Pio Nono and Dent Street",["9"],[-83.662875,32.818668]),
  MaconStop.new("595","Pio Nono and Ell Street",["9"],[-83.662948,32.816637]),
  MaconStop.new("596","Anthony Rd and Arlington Park",["3"],[-83.683351,32.822882]),
  MaconStop.new("597","Anthony Road and Henderson Drive",["3"],[-83.678656,32.825296]),
  MaconStop.new("598","Walmar Street",["6"],[-83.713699,32.783399]),
  MaconStop.new("599","Bloomfield Road and Thrasher Circle",["6"],[-83.707808,32.783499]),
  MaconStop.new("600","Bloomfield Road and Leone Dr",["6"],[-83.707765,32.782548]),
  MaconStop.new("601","Bloomfield Road near Village Green Drive",["6"],[-83.707771,32.781436]),
  MaconStop.new("602","Rocky Creek Road near Apartments",["6"],[-83.676520,32.7862]),
  MaconStop.new("603","Pio Nono Avenue near Rice Mill Road",["6"],[-83.66834,32.792491]),
  MaconStop.new("604","Pio Nono Avenue near Pio Nono Circle",["6"],[-83.664589,32.800062]),
  MaconStop.new("605","Mason Street and Ell Street",["6-O"],[-83.66195,32.816597]),
  MaconStop.new("606","Clinton Road and Pitts Street",["4-O"],[-83.617794,32.862352]),
  MaconStop.new("607","Coliseum Drive and Clinton Street",["11"],[-83.617249,32.84300]),
  MaconStop.new("608","Main Street and Garden Street",["11-I"],[-83.615099,32.844172]),
  MaconStop.new("609","Main Street and Fairview Avenue",["11-I"],[-83.611102,32.845611]),
  MaconStop.new("610","Woolfolk Street and Fort Hill Street",["11-O"],[-83.61265,32.849688]),
  MaconStop.new("611","New Clinton Road and Companion Drive",["11-O"],[-83.587180,32.858516]),
  MaconStop.new("612","New Clinton Road and Ollie Drive",["11-O"],[-83.586725,32.859745]),
  MaconStop.new("613","Jordan Avenue and Recreation Road",["11"],[-83.573823,32.852951]),
  MaconStop.new("614","Jordan Avenue",["11"],[-83.573816,32.853931]),
  MaconStop.new("615","Commodore Drive and Gateway Avenue",["11"],[-83.573806,32.868854]),
  MaconStop.new("616","Truitt Place and Pasadena Drive",["11"],[-83.570259,32.869615]),
  MaconStop.new("617","Strattford Drive and Bethune Avenue",["11"],[-83.57287,32.865759])
  ]
  closestStation = nil
  closestDistance = 100000
  stations.each do |station|
    # if it's Saturday, don't count stops where bus is not running on Saturday
    if(weekday == 6 and station.getroute()[0].split("-")[0] == "1")
      next
    end
    # LIBRARY FIX: can't get to library on weekdays via Route 13
    if(weekday < 6 and station.getroute()[0].split("-")[0] == "13")
      next
    end
    dist = (station.getlat() - lat )**2 + ( station.getlng() - lng )**2
    if(dist < closestDistance)
      closestDistance = dist
      closestStation = station
    end
  end
  return closestStation
end

def closest_bart(lat, lng)
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
  closestStation = nil
  closestDistance = 100000
  stations.each do |station|
    dist = (station.getlat() - lat )**2 + ( station.getlng() - lng )**2
    if(dist < closestDistance)
      closestDistance = dist
      closestStation = station
    end
  end
  return closestStation
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

def hmarray_to_time(hm)
  eventTime = ''
  if hm[0].to_i == 0
    eventTime = '12:' + hm[1] + "am"
  elsif hm[0].to_i < 12
    eventTime = hm[0] + ':' + hm[1] + "am"      
  elsif hm[0].to_i == 12
    eventTime = '12:' + hm[1] + "pm"
  else
    eventTime = (hm[0].to_i - 12).to_s + ':' + hm[1] + "pm"
  end
  return eventTime
end

def getSchedule(route)
  if route == "1-W"
    # turnaround is the index of the furthest stop on the route
    # once the bus is past the turnaround stop, it changes from outbound to inbound
    # Here it is the 3rd stop (6:35 at Kroger) so we use the array index, 2
    return { "turnaround" => 2,
    "stations" => [ "Terminal Station", "Pio Nono Ave at Vineville Ave Outbound", "Zebulon Rd at Kroger", "Coliseum Northside Hospital", "Ridge Ave at Ingleside Ave", "Pio Nono Ave at Vineville Ave Inbound","Terminal Station" ],
    "times" => [
["6:20","6:25","6:35","6:40","6:43","6:48","7:00"],
["7:00","7:07","7:20","7:33","7:38","7:43","8:00"],
["8:00","8:07","8:20","8:33","8:38","8:43","9:00"],
["9:00","9:07","9:20","9:33","9:38","9:43","10:00"],
["10:00","10:07","10:20","10:33","10:38","10:43","11:00"],
["11:00","11:07","11:20","11:33","11:38","11:43","12:00"],
["12:00","12:07","12:20","12:33","12:38","12:43","13:00"],
["13:00","13:07","13:20","13:33","13:38","13:43","14:00"],
["14:00","14:07","14:20","14:33","14:38","14:43","15:00"],
["15:00","15:07","15:20","15:33","15:38","15:43","16:00"],
["16:00","16:07","16:20","16:33","16:38","16:43","17:00"],
["17:00","17:07","17:20","17:33","17:38","17:43","18:00"],
["18:00","18:07","18:20","18:33","18:38","18:43","18:55"]] }

  elsif route == "2-S"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Log Cabin Dr at Hollingsworth Rd","N Napier Apartments Outbound","Zebulon Rd at Kroger","N Napier Apartments Inbound","Napier at Pio Nono", "Terminal Station" ],
    "times" => [
["","","5:45","5:50","5:55","6:10","6:20"],
["5:45","6:05","6:15","6:20","6:30","6:45","6:55"],
["6:20","6:35","6:41","6:50","7:00","7:10","7:25"],
["6:55","7:15","7:30","7:40","7:43","7:50","8:05"],
["7:25","7:41","7:48","7:58","8:08","8:25","8:40"],
["8:05","8:21","8:28","8:38","8:48","9:05","9:20"],
["8:40","8:56","9:03","9:13","9:23","9:40","9:55"],
["9:20","9:36","9:43","9:53","10:03","10:20","10:35"],
["9:55","10:11","10:18","10:28","10:38","10:55","11:10"],
["10:35","10:51","10:58","11:08","11:18","11:35","11:50"],
["11:10","11:26","11:33","11:43","11:53","12:10","12:25"],
["11:50","12:06","12:13","12:23","12:33","12:50","13:05"],
["12:25","12:41","12:48","12:58","13:08","13:25","13:40"],
["13:05","13:21","13:28","13:38","13:48","14:05","14:20"],
["13:40","13:56","14:03","14:13","14:23","14:40","14:55"],
["14:20","14:36","14:43","14:53","15:03","15:20","15:35"],
["14:55","15:11","15:18","15:28","15:38","15:55","16:10"],
["15:35","15:51","15:58","16:08","16:18","16:35","16:50"],
["16:10","16:26","16:33","16:43","16:53","17:10","17:25"],
["16:50","17:06","17:13","17:23","17:33","17:50","18:05"],
["17:25","17:40","17:48","17:56","18:10","18:25","18:40"],
["18:05","18:20","18:26","18:34","18:42","18:55","19:05"],
["18:40","18:53","19:00","19:08","19:16","19:30","19:45"]
            ] }
  elsif route == "2-W"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","N Napier Apartments Outbound","Zebulon Rd at Kroger","Forsyth Rd at Park St","N Napier Apartments Inbound","Napier at Pio Nono","Terminal Station"],
    "times" => [
["","5:45","5:51","","5:57","6:09","6:20"],
["5:45","6:10","6:25","","6:35","6:50","7:00"],
["6:20","6:40","","6:47","6:52","7:05","7:25"],
["7:00","7:25","","7:30","7:35","7:50","8:05"],
["7:25","7:50","","8:02","8:07","8:24","8:40"],
["8:05","8:30","","8:35","8:40","8:55","9:20"],
["8:40","9:05","","9:12","9:17","9:32","9:55"],
["9:20","9:45","","9:50","9:55","10:10","10:35"],
["9:55","10:15","","10:22","10:27","10:45","11:10"],
["10:35","11:00","","11:05","11:10","11:25","11:50"],
["11:10","11:30","","11:37","11:43","12:00","12:25"],
["11:50","12:15","","12:20","12:25","12:40","13:05"],
["12:25","12:48","","12:55","13:00","13:17","13:40"],
["13:05","13:30","","13:35","13:40","13:55","14:20"],
["13:40","14:00","","14:07","14:12","14:29","14:55"],
["14:20","14:45","","14:50","14:55","15:10","15:35"],
["14:55","15:18","","15:25","15:32","15:49","16:10"],
["15:35","16:00","","16:05","16:10","16:25","16:50"],
["16:10","16:33","","16:40","16:45","17:05","17:25"],
["16:50","17:12","","17:17","17:22","17:37","18:05"],
["17:25","17:48","","17:55","18:00","18:20","18:40"],
["18:05","18:28","","18:33","18:38","18:55","19:20"],
["18:40","18:55","19:08","","19:22","19:32","19:45"],
["19:45","19:55","20:13","","20:27","20:37","20:55"],
["20:55","21:05","21:10","","21:37","21:47","22:00"],
["22:00","22:10","22:41","","22:51","22:58", "" ] ] }

  elsif route == "3-S"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Montpelier Av at Pio Nono Ave Outbound","Wren Ave at Mallard Av Outbound","Thomaston Rd at Food Lion","Wren Ave at Mallard Av Inbound","Pio Nono at Montpelier Av Inbound","Terminal Station" ],
    "times" => [
["","5:37","","5:50","6:00","6:10","6:20"],
["6:20","6:30","6:40","6:50","7:00","7:10","7:25"],
["7:25","7:35","7:45","8:00","8:15","8:25","8:40"],
["8:40","8:50","9:00","9:15","9:30","9:40","9:55"],
["9:55","10:05","10:15","10:30","10:45","10:55","11:10"],
["11:10","11:20","11:30","11:45","12:00","12:10","12:25"],
["12:25","12:35","12:45","13:00","13:15","13:25","13:40"],
["13:40","13:50","14:00","14:15","14:30","14:40","14:55"],
["14:55","15:05","15:15","15:30","15:45","15:55","16:10"],
["16:10","16:20","16:30","16:45","17:00","17:10","17:25"],
["17:25","17:35","17:45","18:00","18:15","18:25","18:40"],
["18:40","18:48","18:58","19:10","19:20","19:30","19:45"]
              ] }
  elsif route == "3-W"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Montpelier Av at Pio Nono Ave Outbound","Wren Ave at Mallard Av Outbound","Thomaston Rd at Food Lion","Wren Ave at Mallard Av Inbound","Pio Nono at Montpelier Av Inbound","Terminal Station" ],
    "times" => [
["","5:37","","5:50","6:00","6:10","6:20"],
["5:45","5:53","6:01","6:14","6:30","6:42","6:55"],
["6:20","6:30","6:40","6:50","7:00","7:10","7:25"],
["6:55","7:05","7:15","7:27","7:40","7:50","8:05"],
["7:25","7:35","7:45","8:00","8:15","8:25","8:40"],
["8:05","8:15","8:25","8:40","8:55","9:05","9:20"],
["8:40","8:50","9:00","9:15","9:30","9:40","9:55"],
["9:20","9:30","9:40","9:55","10:10","10:20","10:35"],
["9:55","10:05","10:15","10:30","10:45","10:55","11:10"],
["10:35","10:45","10:55","11:10","11:25","11:35","11:50"],
["11:10","11:20","11:30","11:45","12:00","12:10","12:25"],
["11:50","12:00","12:10","12:25","12:40","12:50","13:05"],
["12:25","12:35","12:45","13:00","13:15","13:25","13:40"],
["13:05","13:15","13:25","13:40","13:55","14:05","14:20"],
["13:40","13:50","14:00","14:15","14:30","14:40","14:55"],
["14:20","14:30","14:40","14:55","15:10","15:20","15:35"],
["14:55","15:05","15:15","15:30","15:45","15:55","16:10"],
["15:35","15:45","15:55","16:10","16:25","16:35","16:50"],
["16:10","16:20","16:30","16:45","17:00","17:10","17:25"],
["16:50","17:00","17:10","17:25","17:40","17:50","18:05"],
["17:25","17:35","17:45","18:00","18:15","18:25","18:40"],
["18:05","18:15","18:25","18:40","18:55","19:05","19:20"],
["18:40","18:48","18:58","19:10","19:20","19:30","19:45"],
["19:45","19:55","20:05","20:17","20:30","20:40","20:55"],
["20:55","21:04","21:12","21:24","21:37","21:45","22:00"],
["22:00","22:08","22:16","22:27","22:38","22:46","22:55"]
              ]}
  elsif route == "4-S"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Spring St at Riverside Dr Outbound","Walnut Hills","Walmart","McAfee Towers","Spring St at Riverside Dr Inbound","Terminal Station" ],
    "times" => [
["","5:53","6:04","","6:10","6:15","6:20"],
["6:20","6:25","6:40","","6:50","6:55","7:00"],
["7:00","7:07","7:23","7:29","7:44","7:51","8:00"],
["8:00","8:07","8:23","8:29","8:44","8:51","9:00"],
["9:00","9:07","9:23","9:29","9:44","9:51","10:00"],
["10:00","10:07","10:23","10:29","10:44","10:51","11:00"],
["11:00","11:07","11:23","11:29","11:44","11:51","12:00"],
["12:00","12:07","12:23","12:29","12:44","12:51","13:00"],
["13:00","13:07","13:23","13:29","13:44","13:51","14:00"],
["14:00","14:07","14:23","14:29","14:44","14:51","15:00"],
["15:00","15:07","15:23","15:29","15:44","15:51","16:00"],
["16:00","16:07","16:23","16:29","16:44","16:51","17:00"],
["17:00","17:07","17:17","17:29","17:44","17:51","18:00"],
["18:00","18:07","18:15","18:29","18:44","18:51","19:00"],
["19:00","19:07","19:23","19:29","19:44","19:51","20:00"]
              ]}
  elsif route == "4-W"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Spring St at Riverside Dr Outbound","Walnut Hills","Walmart","McAfee Towers","Spring St at Riverside Dr Inbound","Terminal Station" ],
    "times" => [
["","5:53","6:04","","6:10","6:15","6:20"],
["6:20","6:25","6:40","","6:50","6:55","7:00"],
["7:00","7:07","7:23","7:29","7:44","7:51","8:00"],
["8:00","8:07","8:23","8:29","8:44","8:51","9:00"],
["9:00","9:07","9:23","9:29","9:44","9:51","10:00"],
["10:00","10:07","10:23","10:29","10:44","10:51","11:00"],
["11:00","11:07","11:23","11:29","11:44","11:51","12:00"],
["12:00","12:07","12:23","12:29","12:44","12:51","13:00"],
["13:00","13:07","13:23","13:29","13:44","13:51","14:00"],
["14:00","14:07","14:23","14:29","14:44","14:51","15:00"],
["15:00","15:07","15:23","15:29","15:44","15:51","16:00"],
["16:00","16:07","16:23","16:29","16:44","16:51","17:00"],
["17:00","17:07","17:17","17:29","17:44","17:51","18:00"],
["18:00","18:07","18:15","18:29","18:44","18:51","19:00"],
["19:00","19:07","19:23","19:29","19:44","19:51","20:00"],
["20:00","20:07","20:23","20:29","20:44","20:51","21:00"],
["21:00","21:07","21:23","21:29","21:44","21:51","22:00"],
["22:00","22:07","22:23","22:29","22:44","22:51","22:55"]              
              ]}
  elsif route == "5-S"
    return { "turnaround" => 3,
    "stations" => ["Terminal Station","2nd Ave at I-75","Pierce Ave at Riverside Dr","Kmart at Kroger","Riverside Dr at Kroger","Baxter Ave at Riverside Dr","3rd Ave at I-75","Terminal Station"],
    "times" => [
["","","5:41","5:48","5:55","6:00","6:05","6:20"],
["6:20","6:30","6:37","6:45","6:53","7:01","7:06","7:25"],
["7:25","7:40","7:48","8:00","8:10","8:15","8:23","8:40"],
["8:40","8:53","9:01","9:13","9:23","9:31","9:36","9:55"],
["9:55","10:08","10:16","10:28","10:37","10:46","10:51","11:10"],
["11:10","11:23","11:31","11:43","11:53","12:01","12:06","12:25"],
["12:25","12:38","12:46","12:58","13:08","13:16","13:21","13:40"],
["13:40","13:53","14:01","14:13","14:23","14:31","14:36","14:55"],
["14:55","15:08","15:16","15:28","15:38","15:46","15:51","16:10"],
["16:10","16:23","16:31","16:43","16:53","17:01","17:06","17:25"],
["17:25","17:38","17:46","17:58","18:08","18:16","18:21","18:40"],
["18:40","18:50","18:57","19:06","19:14","19:21","19:26","19:45"]
              ]}
  elsif route == "5-W"
    return { "turnaround" => 4,
    "stations" => ["Terminal Station","2nd Ave at I-75","Pierce Ave at Riverside Dr","Kmart at Kroger","Connect to North Macon","Riverside Dr at Kroger","Baxter Ave at Riverside Dr","3rd Ave at I-75","Terminal Station"],
    "times" => [
["","","5:41","5:48","","5:55","6:00","6:05","6:20"],
["","6:04","6:12","6:20","6:20","6:27","6:32","6:37","6:50"],
["6:20","6:30","6:37","6:45","6:45","6:53","7:01","7:06","7:25"],
["6:55","7:08","7:16","7:25","7:25","7:33","7:41","7:46","8:00"],
["7:25","7:40","7:48","8:00","8:00","8:10","8:15","8:23","8:40"],
["8:05","8:20","8:28","8:40","8:40","8:50","8:55","9:03","9:15"],
["8:40","8:53","9:01","9:13","9:14","9:23","9:31","9:36","9:55"],
["9:20","9:33","9:41","9:53","9:53","10:03","10:11","10:16","10:30"],
["9:55","10:08","10:16","10:28","","10:37","10:46","10:51","11:10"],
["10:35","10:48","10:56","11:08","","11:18","11:26","11:31","11:45"],
["11:10","11:23","11:31","11:43","","11:53","12:01","12:06","12:25"],
["11:50","12:03","12:11","12:23","","12:33","12:41","12:46","13:00"],
["12:25","12:38","12:46","12:58","","13:08","13:16","13:21","13:40"],
["13:05","13:08","13:25","13:38","","13:48","13:56","14:01","14:15"],
["13:40","13:53","14:01","14:13","14:13","14:23","14:31","14:36","14:55"],
["14:20","14:33","14:41","14:53","14:53","15:03","15:11","15:16","15:30"],
["14:55","15:08","15:16","15:28","15:28","15:38","15:46","15:51","16:10"],
["15:35","15:48","15:56","16:08","16:08","16:18","16:26","16:31","16:45"],
["16:10","16:23","16:31","16:43","16:43","16:53","17:01","17:06","17:25"],
["16:50","17:03","17:11","17:23","17:23","17:41","17:46","18:00",""],
["17:25","17:38","17:46","17:58","17:58","18:08","18:16","18:21","18:40"],
["18:05","18:18","18:26","18:38","18:38","18:48","18:56","19:01","19:15"],
["18:40","18:50","18:57","19:06","19:06","19:14","19:21","19:26","19:45"],
["19:45","19:55","20:03","20:15","","20:23","20:30","20:36","20:55"],
["20:55","21:05","21:12","21:22","","21:30","21:37","21:42","22:00"],
["22:00","22:08","22:16","22:26","","22:32","22:38","22:44", ""]
              ]}
  elsif route == "6-S"
    return { "turnaround" => 4,
    "stations" => [ "Terminal Station","Murphy Homes Outbound","Westgate Mall Outbound","Nisbet Rd at Nisbet Dr","Leone Dr at Bloomfield Rd","Westgate Mall Inbound","Murphy Homes Inbound","Terminal Station" ],
    "times" => [
["","","","5:45","5:55","","6:11","6:20"],
["6:20","6:28","","6:48","6:58","","7:13","7:25"],
["7:25","7:35","7:40","7:52","8:07","8:21","8:27","8:40"],
["8:40","8:50","8:55","9:07","9:22","9:36","9:42","9:55"],
["9:55","10:05","10:10","10:22","10:37","10:51","10:57","11:10"],
["11:10","11:20","11:25","11:37","11:52","12:06","12:12","12:25"],
["12:25","12:35","12:40","12:52","13:07","13:21","13:27","13:40"],
["13:40","13:50","13:55","14:07","14:22","14:36","14:42","14:55"],
["14:55","15:05","15:10","15:22","15:37","15:51","15:57","16:10"],
["16:10","16:20","16:25","16:37","16:52","17:06","17:12","17:25"],
["17:25","17:35","17:40","17:52","18:07","18:21","18:27","18:40"],
["18:40","18:47","18:52","19:04","19:17","19:27","19:32","19:45"]
              ]}
  elsif route == "6-W"
    return { "turnaround" => 4,
    "stations" => [ "Terminal Station","Murphy Homes Outbound","Westgate Mall Outbound","Nisbet Rd at Nisbet Dr","Leone Dr at Bloomfield Rd","Westgate Mall Inbound","Murphy Homes Inbound","Terminal Station" ],
    "times" => [
["","","","5:45","5:55","","6:11","6:20"],
["6:20","6:28","","6:48","6:58","","7:13","7:25"],
["7:25","7:35","7:40","7:52","8:07","8:21","8:27","8:40"],
["8:40","8:50","8:55","9:07","9:22","9:36","9:42","9:55"],
["9:55","10:05","10:10","10:22","10:37","10:51","10:57","11:10"],
["11:10","11:20","11:25","11:37","11:52","12:06","12:12","12:25"],
["12:25","12:35","12:40","12:52","13:07","13:21","13:27","13:40"],
["13:40","13:50","13:55","14:07","14:22","14:36","14:42","14:55"],
["14:55","15:05","15:10","15:22","15:37","15:51","15:57","16:10"],
["16:10","16:20","16:25","16:37","16:52","17:06","17:12","17:25"],
["17:25","17:35","17:40","17:52","18:07","18:21","18:27","18:40"],
["18:40","18:47","18:52","19:04","19:17","19:27","19:32","19:45"],
["19:45","19:52","19:57","20:09","20:22","20:36","20:42","20:55"],
["20:55","21:02","21:07","21:17","21:29","21:41","21:47","22:00"],
["22:00","22:05","22:09","22:17","22:29","22:41","22:47","22:55"]
              ]}
  elsif route == "9-S"
    return { "turnaround" => 4,
    "stations" => ["Terminal Station","College St at Mercer Blvd Outbound","Macon Mall","Chambers Rd at Eisenhower Prkway","Macon College","Mercer Blvd at College St Inbound","Terminal Station"],
    "times" => [
["5:50","5:58","","6:15","","6:27","6:38"],
["6:10","6:25","","6:35","","6:45","6:56"],
["6:40","6:50","","7:19","7:23","7:37","7:55"],
["7:00","7:10","","7:35","7:40","8:08","8:25"],
["8:00","8:08","8:25","8:35","8:40","9:10","9:25"],
["8:30","8:38","8:55","9:05","9:10","9:40","9:55"],
["9:30","9:38","9:55","10:05","10:10","10:40","10:55"],
["10:00","10:08","10:25","10:35","10:40","11:10","11:25"],
["11:00","11:08","11:25","11:35","11:40","12:10","12:25"],
["11:30","11:38","11:55","12:05","12:10","12:40","12:55"],
["12:30","12:38","12:55","13:05","13:10","13:40","13:55"],
["13:00","13:08","13:25","13:35","13:40","14:10","14:25"],
["14:00","14:08","14:25","14:35","14:40","15:10","15:25"],
["14:30","14:38","14:55","15:05","15:10","15:40","15:55"],
["15:30","15:38","15:55","16:05","16:10","16:40","16:55"],
["16:00","16:08","16:25","16:35","16:40","17:10","17:25"],
["17:00","17:08","17:25","17:35","17:40","18:20","18:35"],
["18:40","18:48","19:05","19:15","19:20","19:40","19:55"]
              ]}
  elsif route == "9-W"
    return { "turnaround" => 5,
    "stations" => ["Terminal Station","College St at Mercer Blvd","Central Georgia Tech at Eisenhower Prkway","Macon Mall","Chambers Rd at Eisenhower Prkway","Macon College","Central Georgia Tech at Eisenhower Prkway","Mercer Blvd at College St","Terminal Station"],
    "times" => [
["5:20","5:28","","","5:50","","","6:05","6:18"],
["5:50","5:58","","","6:15","","","6:27","6:38"],
["6:00","6:13","","","6:36","","","6:47","6:58"],
["6:20","6:28","","","6:55","","","7:10","7:25"],
["6:40","6:50","","","7:19","","","7:37","7:55"],
["7:00","7:08","7:23","7:25","7:35","7:40","","8:06","8:22"],
["7:30","7:38","7:53","7:55","8:05","8:10","","8:40","8:55"],
["8:00","8:08","8:23","8:25","8:35","8:40","","9:10","9:25"],
["8:30","8:38","8:53","8:55","9:05","9:10","","9:40","9:55"],
["9:00","9:08","9:23","9:25","9:35","9:40","","10:10","10:25"],
["9:30","9:38","9:53","9:55","10:05","10:10","","10:40","10:55"],
["10:00","10:08","10:23","10:25","10:35","10:40","","11:10","11:25"],
["10:30","10:38","10:53","10:55","11:05","11:10","","11:40","11:55"],
["11:00","11:08","11:23","11:25","11:35","11:40","","12:10","12:25"],
["11:30","11:38","11:53","11:55","12:05","12:10","","12:40","12:55"],
["12:00","12:08","","12:25","12:35","12:40","12:53","13:10","13:25"],
["12:30","12:38","","12:55","13:05","13:10","13:23","13:40","13:55"],
["13:00","13:08","","13:25","13:35","13:40","13:53","14:10","14:25"],
["13:30","13:38","","13:55","14:05","14:10","14:23","14:40","14:55"],
["14:00","14:08","","14:25","14:35","14:40","14:53","15:10","15:25"],
["14:30","14:38","","14:55","15:05","15:10","15:23","15:40","15:55"],
["15:00","15:08","","15:25","15:35","15:40","15:53","16:10","16:25"],
["15:30","15:38","","15:55","16:05","16:10","16:23","16:40","16:55"],
["16:00","","16:08","16:25","16:35","16:40","16:53","17:10","17:25"],
["16:30","16:38","","16:55","17:05","17:10","17:23","17:40","17:55"],
["17:00","17:08","","17:25","17:35","17:40","17:53","18:10","18:25"],
["17:30","","17:38","17:55","18:05","18:10","18:23","18:40","18:55"],
["18:00","18:08","","18:25","18:35","18:40","18:53","19:10","19:25"],
["18:30","18:38","","18:55","19:05","19:10","19:23","19:40","19:55"],
["19:00","","19:08","19:25","19:35","19:40","19:53","20:10","20:25"],
["20:00","20:08","","20:25","20:35","20:40","20:53","21:10","21:25"],
["20:30","","20:38","20:55","21:05","21:10","21:23","21:40","21:55"],
["22:00","","22:08","22:18","22:26","22:31","","22:45","22:55"]
              ]}
  elsif route == "11-S"
    return { "turnaround" => 3,
    "stations" => [ "Terminal Station","Fort Hill & Woodfolk Street","Laney Ave and Stratford Drive","Queen's Drive and King Park Drive","Jeffersonville Road and Millerfield Road","Fellowship at Coliseum","Terminal Station" ],
    "times" => [
["","5:25","5:42","5:50","6:00","6:08","6:20"],
["6:20","6:27","6:42","6:50","7:00","7:10","7:25"],
["7:25","7:35","7:52","8:05","8:15","8:25","8:40"],
["8:40","8:50","9:07","9:20","9:30","9:40","9:55"],
["9:55","10:05","10:22","10:35","10:45","10:55","11:10"],
["11:10","11:20","11:37","11:50","12:00","12:10","12:25"],
["12:25","12:35","12:52","13:05","13:15","13:25","13:40"],
["13:40","13:50","14:07","14:20","14:30","14:40","14:55"],
["14:55","15:05","15:22","15:35","15:45","15:55","16:10"],
["16:10","16:20","16:37","16:50","17:00","17:10","17:25"],
["17:25","17:35","17:52","18:05","18:15","18:25","18:40"],
["18:40","18:50","19:07","19:17","19:26","19:35","19:45"]
              ]}
  elsif route == "11-W"
    return { "turnaround" => 3,
    "stations" => ["Terminal Station","Fort Hill & Woodfolk Street","Laney Ave and Stratford Drive","Queen's Drive and King Park Drive","Jeffersonville Road and Millerfield Road","Fellowship at Coliseum","Terminal Station"],
    "times" => [
["","5:25","5:42","5:50","6:00","6:08","6:20"],
["5:45","5:55","6:12","6:20","6:30","6:40","6:55"],
["6:20","6:27","6:42","6:50","7:00","7:10","7:25"],
["6:55","7:05","7:22","7:30","7:40","7:50","8:05"],
["7:25","7:35","7:52","8:05","8:15","8:25","8:40"],
["8:05","8:15","8:32","8:45","8:55","9:05","9:20"],
["8:40","8:50","9:07","9:20","9:30","9:40","9:55"],
["9:20","9:30","9:47","10:00","10:10","10:20","10:35"],
["9:55","10:05","10:22","10:35","10:45","10:55","11:10"],
["10:35","10:45","11:02","11:15","11:25","11:35","11:50"],
["11:10","11:20","11:37","11:50","12:00","12:10","12:25"],
["11:50","12:00","12:17","12:30","12:40","12:50","13:05"],
["12:25","12:35","12:52","13:05","13:15","13:25","13:40"],
["13:05","13:15","13:32","13:45","13:55","14:05","14:20"],
["13:40","13:50","14:07","14:20","14:30","14:40","14:55"],
["14:20","14:20","14:47","15:00","15:10","15:20","15:35"],
["14:55","15:05","15:22","15:35","15:45","15:55","16:10"],
["15:35","15:45","16:02","16:15","16:25","16:35","16:50"],
["16:10","16:20","16:37","16:50","17:00","17:10","17:25"],
["16:50","17:00","17:17","17:30","17:40","17:50","18:00"],
["17:25","17:35","17:52","18:05","18:15","18:25","18:40"],
["18:40","18:50","19:07","19:17","19:26","19:35","19:45"],
["19:45","19:55","20:12","20:25","20:35","20:45","20:55"],
["20:55","21:05","21:22","21:32","21:42","21:49","22:00"],
["22:00","22:08","22:25","22:35","22:42","22:50",""]
              ]}
  elsif route == "12-S"
    return { "turnaround" => 3,
    "stations" => ["Terminal Station","Ponce DeLeon Outbound","5 Points","Houston / Chatman","Ponce DeLeon Inbound","MLK / Oglethorpe","Terminal Station" ],
    "times" => [
["5:40","5:50","","5:58","6:04","6:14","6:18"],
["6:20","6:30","","6:40","6:45","6:55","6:58"],
["7:00","7:10","7:20","7:25","7:30","7:40","7:45"],
["7:50","8:00","","8:15","8:20","8:30","8:35"],
["8:40","8:50","","9:05","9:10","9:20","9:25"],
["9:30","9:40","9:50","9:55","10:00","10:10","10:15"],
["10:20","10:30","","10:45","10:50","11:00","11:05"],
["11:10","11:20","","11:35","11:40","11:50","11:55"],
["12:00","12:10","12:20","12:25","12:30","12:40","12:45"],
["12:50","13:00","","13:15","13:20","13:30","13:35"],
["13:40","13:50","","14:05","14:10","14:20","14:25"],
["14:30","14:40","14:50","14:55","15:00","15:10","15:15"],
["15:20","15:30","","15:45","15:50","16:00","16:05"],
["16:10","16:20","","16:35","16:40","16:50","16:55"],
["17:00","17:10","17:20","17:25","17:30","17:40","17:45"],
["17:50","18:00","","18:15","18:20","18:30","18:35"],
["18:40","18:50","","19:05","19:10","19:20","19:25"]              
              ]}
  elsif route == "12-W"
    return { "turnaround" => 3,
    "stations" => ["Terminal Station","Ponce DeLeon Outbound","5 Points","Houston / Chatman","Ponce DeLeon Inbound","MLK / Oglethorpe","Terminal Station"],
    "times" => [
["5:40","5:50","","5:58","6:04","6:14","6:18"],
["5:45","6:00","6:15","6:20","6:25","6:35","6:38"],
["6:20","6:30","","6:40","6:45","6:55","6:58"],
["6:40","6:50","7:00","7:05","7:10","7:20","7:23"],
["7:00","7:10","","7:25","7:30","7:40","7:45"],
["7:25","7:35","7:50","7:55","8:00","8:10","8:13"],
["7:50","8:00","","8:15","8:20","8:30","8:35"],
["8:15","8:25","","8:40","8:45","8:55","9:03"],
["8:40","8:50","9:00","9:05","9:10","9:20","9:25"],
["9:05","9:15","","9:30","9:35","9:45","9:50"],
["9:30","9:40","","9:55","10:00","10:10","10:15"],
["9:55","10:05","","10:20","10:25","10:35","10:40"],
["10:20","10:30","10:40","10:45","10:50","11:00","11:05"],
["10:45","10:55","","11:10","11:15","11:25","11:30"],
["11:10","11:20","","11:35","11:40","11:50","11:55"],
["11:35","11:45","","12:00","12:05","12:15","12:20"],
["12:00","12:10","","12:25","12:30","12:40","12:45"],
["12:25","12:35","12:45","12:50","12:55","13:05","13:10"],
["12:50","13:00","","13:15","13:20","13:30","13:35"],
["13:15","13:25","","13:40","13:45","13:55","14:00"],
["13:40","13:50","","14:05","14:10","14:20","14:25"],
["14:05","14:15","14:25","14:30","14:35","14:45","14:50"],
["14:30","14:40","","14:55","15:00","15:10","15:15"],
["14:55","15:05","15:15","15:20","15:25","15:35","15:40"],
["15:20","15:30","","15:45","15:50","16:00","16:05"],
["15:45","15:55","","16:10","16:15","16:25","16:30"],
["16:10","16:20","16:30","16:35","16:40","16:50","16:55"],
["16:35","16:45","","17:00","17:05","17:15","17:20"],
["17:00","17:10","17:20","17:25","17:30","17:40","17:45"],
["17:50","18:00","","18:15","18:20","18:30","18:35"],
["18:40","18:50","","19:05","19:10","19:20","19:25"],
["19:30","19:40","19:50","19:55","20:00","20:10","20:15"],
["20:20","20:30","","20:45","20:50","21:00","21:05"],
["21:10","21:20","","21:35","21:40","21:50","21:55"],
["22:00","22:10","22:20","22:25","22:30","22:36","22:40"]
              ]}
  elsif route == "13-W"
    return { "turnaround" => 3,
    "stations" => ["Kmart","I-75 Arkwright","Sheraton Riverside Dr","River Walk Bass Rd","I-75 Exit 171","Kmart I-75","Terminal Station Garage"],
    "times" => [
["6:20","6:24","6:28","6:32","6:40","6:45",""],
["6:50","6:54","6:58","7:06","7:17","7:22",""],
["7:25","7:29","7:33","7:40","7:51","7:56",""],
["8:00","8:04","8:10","8:18","8:30","8:35",""],
["8:40","8:44","8:48","8:53","9:08","9:13",""],
["9:13","9:17","9:21","9:30","9:43","9:48",""],
["9:53","9:57","10:01","10:08","10:19","","10:23"],
["14:15","14:19","14:26","14:33","14:45","14:50",""],
["14:53","14:57","15:01","15:08","15:20","15:24",""],
["15:28","15:33","15:37","15:44","15:58","16:03",""],
["16:08","16:12","16:16","16:23","16:34","16:39",""],
["16:43","16:47","16:51","16:58","17:15","17:20",""],
["17:23","17:27","17:31","17:38","17:50","17:55",""],
["17:58","18:02","18:08","18:15","18:29","18:34",""],
["18:38","18:42","18:46","18:53","19:06","","19:11"]
              ]}

  elsif route == "13-S"
    return { "turnaround" => 6,
    "stations" => ["Terminal Station","Riverside and Spring","Riverside and Baxter","Riverside and Pierce","I-75 and Arkwright","Sheraton Dr. and Riverside","Bass Road","I-75 Exit 171","I-75 Pierce","Terminal Station"],
    "times" => [
["5:55","6:04","6:08","6:16","6:24","6:34","6:40","6:43","6:45","6:50"],
["6:55","7:05","7:10","7:15","7:25","7:30","7:35","7:38","7:45","8:00"],
["8:05","8:15","8:20","8:25","8:35","8:40","8:45","8:48","8:55","9:15"],
["9:20","9:25","9:30","9:35","9:45","9:50","9:55","9:58","10:10","10:30"],
["14:20","14:30","14:35","14:40","14:50","14:55","15:00","15:03","15:10","15:30"],
["15:35","15:45","15:50","15:55","16:05","16:10","16:15","16:18","16:25","16:45"],
["16:50","17:00","17:05","17:10","17:20","17:25","17:30","17:33","17:40","18:00"],
["18:05","18:15","18:20","18:25","18:25","18:35","18:40","18:45","18:55","19:17"]
              ]}
  end
end

configure do
  mime_type :json, 'application/json'
end

get '/json' do
  content_type :json

  if params['route']
    gotime = (Time.now()-60*60*4) 
    if(params['date'])
      timestamp = params['date'].split(",")
      gotime = Time.new( timestamp[0], timestamp[1], timestamp[2], timestamp[3], timestamp[4], 0, "-04:00" )
    end
    
    currentbuses = "{\"route\": " + params['route'] + ",\"timestamp\":\"" + gotime.to_s + "\",\"active_buses\": ["
    
    # no Sunday buses
    if gotime.wday == 0
      return currentbuses + "],\"error\":\"No Sunday buses\"}"
    end

    if params['route'] == "1"
      if gotime.wday < 6
        # Weekday schedule
        sched = getSchedule("1-W")
      else
        # 1 does not run on Saturdays
        return currentbuses + "],\"error\":\"No Saturday buses on Route 1.\"}"
      end

    elsif params['route'] == "2"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("2-S")
      else
        # Weekday schedule
        sched = getSchedule("2-W")
      end

    elsif params['route'] == "3"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("3-S")
      else
        # weekday schedule
        sched = getSchedule("3-W")
      end

    elsif params['route'] == "4"
      if gotime.wday == 6
        sched = getSchedule("4-S")
      else
        sched = getSchedule("4-W")
      end

    elsif params['route'] == "5"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("5-S")
      else
        # weekday schedule
        sched = getSchedule("5-W")
      end
            
    elsif params['route'] == "6"
      if gotime.wday == 6
        sched = getSchedule("6-S")
      else
        sched = getSchedule("6-W")
      end

    elsif params['route'] == "9"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("9-S")
      else
        # weekday schedule
        sched = getSchedule("9-W")
      end

    elsif params['route'] == "11"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("11-S")
      else
        # weekday schedule
        sched = getSchedule("11-W")
      end

    elsif params['route'] == "12"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("12-S")
      else
        # weekday schedule
        sched = getSchedule("12-W")
      end

    elsif params['route'] == "13"
      if gotime.wday == 6
        # Saturday schedule
        sched = getSchedule("13-S")
      else
        # weekday schedule
        sched = getSchedule("13-W")
      end
    end

    wroteABus = 0
    sched["times"].each do |pass|
      # identify the first time this bus stops
      firsttime = ''
      firstindex = 0
      pass.each do |knownstop|
        if knownstop != ""
          firsttime = knownstop.split(":")
          break
        end
        firstindex = firstindex + 1
      end
    
      # identify the last stop this bus will make
      lasttime = ""
      pass.reverse_each do |knownstop|
        if knownstop != ""
          lasttime = knownstop.split(":")
          break
        end
      end
    
      # determine the next stop of this bus
      if lasttime[0].to_i > gotime.hour or (lasttime[0].to_i == gotime.hour and lasttime[1].to_i >= gotime.min)
      
        # determine if this bus has begun service
        if firsttime[0].to_i > gotime.hour or (firsttime[0].to_i == gotime.hour and firsttime[1].to_i >= gotime.min)
          # this bus, and all future buses in the schedule, have not yet left Terminal Station
          currentbuses = currentbuses + "],\"next_new_bus\": { \"next_station\":\"" + sched["stations"][firstindex] + "\", \"time\": \"" + firsttime.join(":") + "\" }}"
          return currentbuses
        end

        # this bus is still somewhere on the road
        currentStation = ""
        stopindex = 0
        pass.each do |knownstop|
          stopindex += 1
          if knownstop == ""
            # doesn't stop here
            next
          end
          knowntime = knownstop.split(":")
          if knowntime[0].to_i > gotime.hour or (knowntime[0].to_i == gotime.hour and knowntime[1].to_i >= gotime.min)
            # this is the bus's next stop
            if wroteABus == 1
              currentbuses = currentbuses + ","
            else
              wroteABus = 1
            end
            if stopindex > sched["turnaround"] + 1
              currentbuses = currentbuses + "{ \"next_station\":\"" + sched["stations"][stopindex-1] + "\", \"direction\":\"inbound\", \"time\":\"" + knowntime.join(":") + "\"}"          
            else
              currentbuses = currentbuses + "{ \"next_station\":\"" + sched["stations"][stopindex-1] + "\", \"direction\":\"outbound\", \"time\":\"" + knowntime.join(":") + "\"}"
            end
            break
          end
        end
      end
    end
    if currentbuses.index("next_new_bus") == nil
      return currentbuses + "],\"error\":\"The next bus leaves tomorrow\"}"
    end
    return currentbuses
  end
end

get '/geotransit' do
  if params['address']
    if params['date']
      timestamp = params['date'].split(",")
      return gogettransit(params['address'], Time.new( timestamp[0], timestamp[1], timestamp[2], timestamp[3], timestamp[4], 0, "-04:00" ))
    else
      return gogettransit(params['address'], (Time.now()-60*60*4)  ) # needs to be real EST/EDT
    end
  elsif params['route']
    if params['date']
      timestamp = params['date'].split(",")
      return gogettransit('Route:' + params['route'], Time.new( timestamp[0], timestamp[1], timestamp[2], timestamp[3], timestamp[4], 0, "-04:00" ))
    else
      return gogettransit('Route:' + params['route'], (Time.now()-60*60*4) ) # needs to be real EST/EDT
    end
  end
  erb :georequest, :locals => { :event => params['event'] }
end

post '/geotransit' do
  gogettransit(params['address'], (Time.now()-60*60*4) )  # needs to be real EST/EDT
end

get '/stopnear' do
  content_type :json

  url = 'http://geocoder.us/service/csv/geocode?address=' + URI.escape(params["address"])
  url = URI.parse(url)
  res = Net::HTTP.start(url.host, url.port) {|http|
    http.get('/service/csv/geocode?address=' + URI.escape(params["address"]))
  }
  response = res.body.split(",")
  lat = Float( response[0] )
  lng = Float( response[1] )

  closest = ''
  closest = closest_macon(lat, lng, 1)  # send Monday so we see all stops
  return '{ "id": "' + closest.getid() + '", "name":"' + closest.getname() + '", "routes": [ ' + closest.getroute().join(',') + ' ], "latlng": [ ' + closest.getlat().to_s + ',' + closest.getlng().to_s + ' ] }'
end

def gogettransit(address, gotime)
  if(address)
    #gotime = Time.now
    if gotime.wday == 0
      return "<!DOCTYPE html>\n<html><body style='font-family:arial'>No Sunday buses</body></html>"
    end
    if address.index('Route:') == nil
      if(address.downcase.index('macon') == nil)
        address += ",Macon,GA"
      end

      url = 'http://geocoder.us/service/csv/geocode?address=' + URI.escape(address)
      url = URI.parse(url)
      res = Net::HTTP.start(url.host, url.port) {|http|
       http.get('/service/csv/geocode?address=' + URI.escape(address))
      }
      response = res.body.split(",")
      lat = Float( response[0] )
      lng = Float( response[1] )

      closest = ''
      bussum = ''
      #if params["city"] == "sf"
      #  closest = closest_bart(lat, lng)
      #  return closest.getid()
      #else # macon
      #  closest = closest_macon(lat, lng, gotime.wday)
      #end
      # assume Macon for now
      closest = closest_macon(lat, lng, gotime.wday)
    else
      closest = MaconStop.new("000","No Place",address.split(":")[1],[0,0])
      lat = 0
      lng = 0
      bussum = ''
      #return closest.getroute()
    end
    if(address)
      turntime = [ ]
      endtime = [ ]
      firsttime = [ ]
      
      busout = "<div style='background-color:silver;border-bottom:1px solid #444;padding:2px;width:100%;'>Directions to library from:</div>"

      if ( closest.hasroute("1") and gotime.wday < 6 ) or closest.hasroute("2") or closest.hasroute("7")
        # library routes
        terminalx = -83.623976
        terminaly = 32.833738
        libraryx = -83.63824
        libraryy = 32.838782
        stopdist = ( closest.getlng() - terminalx )**2 + ( closest.getlat() - terminaly )**2
        librarydist = ( libraryx - terminalx )**2 + ( libraryy - terminaly )**2

        if closest.hasroute("1") and gotime.wday < 6
          if gotime.wday < 6
            # Weekday schedule
            sched = getSchedule("1-W")
          end

        elsif closest.hasroute("2")
          routes = closest.getroute()
          if routes.index("2") != nil or routes.index("2-I") != nil or routes.index("2-O") != nil
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("2-S")
            else
              # Weekday schedule
              sched = getSchedule("2-W")
            end
          elsif gotime.wday == 6 or gotime.hour < 6 or gotime.hour > 18
            # Route 2B
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("2-S")
            else
              # Weekday schedule
              sched = getSchedule("2-W")
            end
          end
        end

        if librarydist < stopdist
          busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station. Arrive at library."
          dothispass = -1
          sched["times"].each do |pass|
            stopdex = 0
            pass.each do |stop|
              if stopdex >= sched["turnaround"] and stop != ""
                turntime = stop.split(":")
                break
              end
              stopdex = stopdex + 1
            end
            if turntime[0].to_i * 60 + turntime[1].to_i >= gotime.hour * 60 + gotime.min
              dothispass = pass
              break
            end
          end
          if dothispass == -1
            busout += "<br/>There are no more inbound buses today"
          else
            busout += "<br/>The next bus will go inbound on this route at " + hmarray_to_time(turntime)
          end
          return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<br/><a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
        
        else
          busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> outbound from Terminal Station. Arrive at library."
          dothispass = -1
          sched["times"].each do |pass|
            pass.each do |stop|
              if stop != ""
                firsttime = stop.split(":")
                break
              end
            end
            if firsttime[0].to_i * 60 + firsttime[1].to_i >= gotime.hour * 60 + gotime.min
              dothispass = pass
              break
            end
          end
          if dothispass == -1
            busout += "<br/>There are no more outbound buses today"
          else
            busout += "<br/>The next bus will go outbound on this route at " + hmarray_to_time(firsttime)
          end
          return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
        end
      else
        if closest.getroute().index("0") == nil  # this route is assigned when none are known
          # look up non-library-connected routes
          sendMeOutbound = 0 # for stops only going outbound
          if closest.hasroute("3")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("3-S")
            else
              # weekday schedule
              sched = getSchedule("3-W")
            end
            if closest.hasroute("3-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (3) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("4")
            if gotime.wday == 6
              sched = getSchedule("4-S")
            else
              sched = getSchedule("4-W")
            end
            if closest.hasroute("4-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (4) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("5")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("5-S")
            else
              # weekday schedule
              sched = getSchedule("5-W")
            end
            if closest.hasroute("5-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (5) from <i>" + closest.getname() + "</i> to Terminal Station."
            
          elsif closest.hasroute("6")
            if gotime.wday == 6
              sched = getSchedule("6-S")
            else
              sched = getSchedule("6-W")
            end
            if closest.hasroute("6-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (6) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("9")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("9-S")
            else
              # weekday schedule
              sched = getSchedule("9-W")
            end
            if closest.hasroute("9-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (9) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("11")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("11-S")
            else
              # weekday schedule
              sched = getSchedule("11-W")
            end
            if closest.hasroute("11-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (11) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("12")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("12-S")
            else
              # weekday schedule
              sched = getSchedule("12-W")
            end
            if closest.hasroute("12-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (12) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("13")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("13-S")
            else
              # weekday schedule
              sched = getSchedule("13-W")
            end
            if closest.hasroute("13-O")
              sendMeOutbound = 1
            end
            busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (13) from <i>" + closest.getname() + "</i> to Terminal Station."
          
          end
          
          dothispass = -1
          turntime = ""
          endtime = ""

          sched["times"].each do |pass|
            if sendMeOutbound == 1
              pass.each do |stop|
                if stop != ""
                  turntime = stop.split(":")
                  break
                end
              end
              pass.reverse_each do |stop|
                if stop != ""
                  endtime = stop.split(":")
                  break
                end
              end
              if turntime[0].to_i * 60 + turntime[1].to_i >= gotime.hour * 60 + gotime.min
                dothispass = pass
                break
              end
              
            else
              stopdex = 0
              pass.each do |stop|
                if stopdex >= sched["turnaround"] and stop != ""
                  turntime = stop.split(":")
                  break
                end
                stopdex = stopdex + 1
              end
              pass.reverse_each do |stop|
                if stop != ""
                  endtime = stop.split(":")
                  break
                end
              end
              if turntime[0].to_i * 60 + turntime[1].to_i >= gotime.hour * 60 + gotime.min
                dothispass = pass
                break
              end
            end
          end
            
          if dothispass == -1
            busout += "<br/>There are no more buses on that route today"
            return busout
          else
            if sendMeOutbound == 1
              busout += "<br/>The next bus will leave Terminal Station on this route at " + hmarray_to_time(turntime) + " and return to Terminal Station at " + hmarray_to_time(endtime)
            else
              busout += "<br/>The next bus will go inbound on this route at " + hmarray_to_time(turntime) + " and return to Terminal Station at " + hmarray_to_time(endtime)
            end
          end
          
          # Now catch the next 2 bus from Terminal Station
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("2-S")
          else
            # Weekday schedule
            sched = getSchedule("2-W")
          end
          
          sched["times"].each do |pass|
            pass.each do |stop|
              if stop != ""
                firsttime = stop.split(":")
                break
              end
            end
            if firsttime[0].to_i * 60 + firsttime[1].to_i >= endtime[0].to_i * 60 + endtime[1].to_i
              dothispass = pass
              break
            end
          end
          busout += "<br/>Then you catch the next Route 2 bus, which leaves at " + hmarray_to_time(firsttime)
          
          return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
          
        else
          # go to Terminal Station
          busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station."
          return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
        end
      end
    end
  else
    return "<br/>no address"
  end
end

def nextStopOn(gotime, sched )
  currentbuses = ''
  sched["times"].each do |pass|
    # identify the first time this bus stops
    firsttime = ''
    firstindex = 0
    pass.each do |knownstop|
      if knownstop != ""
        firsttime = knownstop.split(":")
        break
      end
      firstindex = firstindex + 1
    end
    
    # identify the last stop this bus will make
    lasttime = ''
    pass.reverse_each do |knownstop|
      if knownstop != ""
        lasttime = knownstop.split(":")
        break
      end
    end
    
    # determine the next stop of this bus
    if lasttime[0].to_i > gotime.hour or (lasttime[0].to_i == gotime.hour and lasttime[1].to_i >= gotime.min)
      
      # determine if this bus has begun service
      if firsttime[0].to_i > gotime.hour or (firsttime[0].to_i == gotime.hour and firsttime[1].to_i >= gotime.min)
        # this bus, and all future buses in the schedule, have not yet left Terminal Station
        if currentbuses == ''
          # first bus has not left yet
          return '<br/>The first bus will leave ' + sched["stations"][firstindex] + ' at ' + firsttime.join(":")
        else
          return currentbuses + '<br/>The next bus departs ' + sched["stations"][firstindex] + ' at ' + firsttime.join(":")
        end
      end

      # this bus is still somewhere on the road
      currentStation = ""
      stopindex = 0
      pass.each do |knownstop|
        stopindex += 1
        if knownstop == ""
          # doesn't stop here
          next
        end
        knowntime = knownstop.split(":")
        if knowntime[0].to_i > gotime.hour or (knowntime[0].to_i == gotime.hour and knowntime[1].to_i >= gotime.min)
          # this is the bus's next stop
          currentbuses = currentbuses + "<br/>Next known stop: " + sched["stations"][stopindex-1] + " at " + knowntime.join(":")
          break
        end
      end
    end
  end
  if currentbuses == ''
    return "<br/>The next bus will be tomorrow"
  end
  return currentbuses
end

get '/transit' do
  if params['eventname']
    @tevents = TransitEvent.search(params['eventname'])
    
    eventDest = @tevents.first.gotostation
    if eventDest.index(',') != nil
      # Macon Event
      

    else
      # SF / BART Event
      eventMMDDYYYY = @tevents.first.dateof
      eventTimeStamp = @tevents.first.timeof
      eventTimeStamp = eventTimeStamp.sub(' ','')
      eventTime = ''
      if eventTimeStamp.split(":")[0].to_i == 0
        eventTime = '12:' + eventTimeStamp.split(":")[1] + "%20am"
      elsif eventTimeStamp.split(":")[0].to_i < 12
        eventTime = eventTimeStamp.split(":")[0] + ':' + eventTimeStamp.split(":")[1] + "%20am"      
      elsif eventTimeStamp.split(":")[0].to_i == 12
        eventTime = '12:' + eventTimeStamp.split(":")[1] + "%20pm"
      else
        eventTime = (eventTimeStamp.split(":")[0].to_i - 12).to_s + ':' + eventTimeStamp.split(":")[1] + "%20pm"
      end
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
      erb :transitposted, :locals => { :narrative => narrative, :carbon => carbon }
    end
  else
    erb :transit
  end
end

post '/transit' do
  if params['eventname']
    t_evt = TransitEvent.create!(params)
    erb :eventembed, :locals => { :event => t_evt, :just_created => "true" }
  end
end

get '/event' do
  if params['name']
    t_evt = TransitEvent.first( :eventname => params['name'] )
    erb :eventembed, :locals => { :event => t_evt, :just_created => "false" }
  end
end

get '/routeit' do
  if(params['address'])
    # load the event and its timestamp
    event = TransitEvent.first( :eventname => params['eventname'] )

    day = event.dateof.split('/')[0].to_i()
    month = event.dateof.split('/')[1].to_i()
    year = event.dateof.split('/')[2].to_i()    
    hour = event.timeof.split(':')[0].to_i()
    minute = event.timeof.split(':')[1].to_i()
    return minute.to_s()

    gotime = Time.new( year, month, day, hour, minute, 0, "-04:00" )

    # No Sunday buses
    if gotime.wday == 0
      return "<!DOCTYPE html>\n<html><body style='font-family:arial'>No Sunday buses</body></html>"
    end

    # convert user's address to their nearest bus stop active today
    address = params['address']
    if(address.downcase.index('macon') == nil)
      address += ",Macon,GA"
    end
    url = 'http://geocoder.us/service/csv/geocode?address=' + URI.escape(address)
    url = URI.parse(url)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get('/service/csv/geocode?address=' + URI.escape(address))
    }
    response = res.body.split(",")
    lat = Float( response[0] )
    lng = Float( response[1] )
    closest = closest_macon(lat, lng, gotime.wday)

    # convert event address to its nearest bus stop
    # TODO: set the bus stop once, before entering into the database
    gopoint = event.gotostation
    if(gopoint.downcase.index('macon') == nil)
      gopoint += ",Macon,GA"
    end
    url = 'http://geocoder.us/service/csv/geocode?address=' + URI.escape(gopoint)
    url = URI.parse(url)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get('/service/csv/geocode?address=' + URI.escape(gopoint))
    }
    response = res.body.split(",")
    lat = Float( response[0] )
    lng = Float( response[1] )
    gostation = closest_macon(lat, lng, gotime.wday)

    bussum = ''
    turntime = [ ]
    endtime = [ ]
    firsttime = [ ]
      
    busout = "<div style='background-color:silver;border-bottom:1px solid #444;padding:2px;width:100%;'>Directions to event from:</div>"

    # look for routes shared between the start and end stops
    sameroutes = nil
    closest.getroute().each do |rt|
      if gostation.hasroute(rt.split('-')[0])
        # prevent invalid route-day matches ( in this case, Rt 1 on a Saturday ) 
        if (rt != "1" or gotime.wday < 6)
          sameroutes = rt
          break
        end
      end
    end

    if sameroutes != nil
      # possible to take the same bus route
      # get schedule
      sendMeOutbound = 0 # for stops only going outbound
      if sameroutes == "1"
        if gotime.wday < 6
          # Weekday schedule
          sched = getSchedule("1-W")
        end

      elsif sameroutes == "2"
        routes = closest.getroute()
        if routes.index("2") != nil or routes.index("2-I") != nil or routes.index("2-O") != nil
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("2-S")
          else
            # Weekday schedule
            sched = getSchedule("2-W")
          end
        elsif gotime.wday == 6 or gotime.hour < 6 or gotime.hour > 18
          # Route 2B
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("2-S")
          else
            # Weekday schedule
            sched = getSchedule("2-W")
          end
        end

      elsif sameroutes == "3"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("3-S")
        else
          # weekday schedule
          sched = getSchedule("3-W")
        end
        if closest.hasroute("3-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (3) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "4"
        if gotime.wday == 6
          sched = getSchedule("4-S")
        else
          sched = getSchedule("4-W")
        end
        if closest.hasroute("4-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (4) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "5"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("5-S")
        else
          # weekday schedule
          sched = getSchedule("5-W")
        end
        if closest.hasroute("5-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (5) from <i>" + closest.getname() + "</i> to Terminal Station."
            
      elsif sameroutes == "6"
        if gotime.wday == 6
          sched = getSchedule("6-S")
        else
          sched = getSchedule("6-W")
        end
        if closest.hasroute("6-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (6) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "9"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("9-S")
        else
          # weekday schedule
          sched = getSchedule("9-W")
        end
        if closest.hasroute("9-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (9) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "11"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("11-S")
        else
          # weekday schedule
          sched = getSchedule("11-W")
        end
        if closest.hasroute("11-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (11) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "12"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("12-S")
        else
          # weekday schedule
          sched = getSchedule("12-W")
        end
        if closest.hasroute("12-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (12) from <i>" + closest.getname() + "</i> to Terminal Station."

      elsif sameroutes == "13"
        if gotime.wday == 6
          # Saturday schedule
          sched = getSchedule("13-S")
        else
          # weekday schedule
          sched = getSchedule("13-W")
        end
        if closest.hasroute("13-O")
          sendMeOutbound = 1
        end
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (13) from <i>" + closest.getname() + "</i> to Terminal Station."
      end

      # determine direction by which stop is closer to Terminal Station
      terminalx = -83.623976
      terminaly = 32.833738
      startdist = ( closest.getlng() - terminalx )**2 + ( closest.getlat() - terminaly )**2
      enddist = ( gostation.getlng() - terminalx )**2 + ( gostation.getlat() - terminaly )**2
      turntime = ""
      lasttime = ""

      if startdist > enddist
        # move closer to Terminal Station
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station. Arrive at event."
        dothispass = -1
        # find the latest bus on the schedule which reaches Terminal Station before this event
        # direct them to catch it at the inbound turning time
        sched["times"].reverse_each do |pass|
          # Terminal Station time
          pass.reverse_each do |stop|
            if stop != ""
              lasttime = stop.split(":")
              break
            end
          end
          if lasttime[0].to_i * 60 + lasttime[1].to_i <= gotime.hour * 60 + gotime.min
            dothispass = pass
            break
          end
        end
        # inbound turning time
        stopdex = 0
        dothispass.each do |stop|
          if stopdex >= sched["turnaround"] and stop != ""
            turntime = stop.split(":")
            break
          end
          stopdex = stopdex + 1
        end
        if dothispass == -1
          busout += "<br/>There are no more inbound buses today"
        else
          busout += "<br/>The next bus will go inbound on this route at " + hmarray_to_time(turntime)
        end
        return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<br/><a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
        
      else
        # move along the route away from Terminal Station
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> outbound from Terminal Station. Arrive at library."
        dothispass = -1
        # find the latest bus on the schedule which reaches inbound turning point before this event
        # direct them to catch it at the time it starts the route (usually when leaving Terminal Station)
        sched["times"].reverse_each do |pass|
          # inbound turntime
          stopdex = 0
          pass.each do |stop|
            if stopdex >= sched["turnaround"] and stop != ""
              turntime = stop.split(":")
              break
            end
            stopdex = stopdex + 1
          end
          if turntime[0].to_i * 60 + turntime[1].to_i <= gotime.hour * 60 + gotime.min
            dothispass = pass
            break
          end
        end
        # firsttime
        pass.each do |stop|
          if stop != ""
            firsttime = stop.split(":")
            break
          end
        end
        if dothispass == -1
          busout += "<br/>There are no more outbound buses today"
        else
          busout += "<br/>The next bus will go outbound on this route at " + hmarray_to_time(firsttime)
        end
        return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
      end
    else
      # take a route toward Terminal Station, then transfer
      # figure out the second leg first ( route from Terminal Station to event )
      if gostation.getroute().index("0") == nil  # this route is assigned when none are known
        sendMeOutbound = 1 # must head outbound to the event

        if gostation.hasroute("1") and gotime.wday < 6
          if gotime.wday < 6
            # Weekday schedule
            sched = getSchedule("1-W")
          end
          busout += bussum + "<br/>Take bus (1) from <i>" + closest.getname() + "</i> from Terminal Station"

        elsif gostation.hasroute("2")
          routes = closest.getroute()
          if routes.index("2") != nil or routes.index("2-I") != nil or routes.index("2-O") != nil
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("2-S")
            else
              # Weekday schedule
              sched = getSchedule("2-W")
            end
          elsif gotime.wday == 6 or gotime.hour < 6 or gotime.hour > 18
            # Route 2B
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("2-S")
            else
              # Weekday schedule
              sched = getSchedule("2-W")
            end
          end
          busout += bussum + "<br/>Take bus (2) from <i>" + closest.getname() + "</i> from Terminal Station"

        elsif gostation.hasroute("3")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("3-S")
          else
            # weekday schedule
            sched = getSchedule("3-W")
          end
          busout += bussum + "<br/>Take bus (3) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("4")
          if gotime.wday == 6
            sched = getSchedule("4-S")
          else
            sched = getSchedule("4-W")
          end
          busout += bussum + "<br/>Take bus (4) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("5")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("5-S")
          else
            # weekday schedule
            sched = getSchedule("5-W")
          end
          busout += bussum + "<br/>Take bus (5) from <i>" + closest.getname() + "</i> from Terminal Station."
            
        elsif gostation.hasroute("6")
          if gotime.wday == 6
            sched = getSchedule("6-S")
          else
            sched = getSchedule("6-W")
          end
          busout += bussum + "<br/>Take bus (6) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("9")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("9-S")
          else
            # weekday schedule
            sched = getSchedule("9-W")
          end
          busout += bussum + "<br/>Take bus (9) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("11")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("11-S")
          else
            # weekday schedule
            sched = getSchedule("11-W")
          end
          busout += bussum + "<br/>Take bus (11) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("12")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("12-S")
          else
            # weekday schedule
            sched = getSchedule("12-W")
          end
          busout += bussum + "<br/>Take bus (12) from <i>" + closest.getname() + "</i> from Terminal Station."

        elsif gostation.hasroute("13")
          if gotime.wday == 6
            # Saturday schedule
            sched = getSchedule("13-S")
          else
            # weekday schedule
            sched = getSchedule("13-W")
          end
          busout += bussum + "<br/>Take bus (13) from <i>" + closest.getname() + "</i> from Terminal Station."
          
        end
          
        dothispass = -1
        turntime = ""
        endtime = ""
        firsttime = ""

        # find latest pass reaching a turntime before event
        # then tell them when that pass leaves Terminal Station
        sched["times"].reverse_each do |pass|
          pass.each do |stop|
            if stopdex >= sched["turnaround"] and stop != ""
              turntime = stop.split(":")
              break
            end
          end
          if turntime[0].to_i * 60 + turntime[1].to_i <= gotime.hour * 60 + gotime.min
            dothispass = pass
            break
          end
        end
        dothispass.each do |stop|
          if stop != ""
            firsttime = stop.split(":")
            break
          end
        end
        
        # if the event cannot be reached from Terminal Station, don't bother finding first leg of the trip
        if dothispass == -1
          busout += "<br/>There are no more buses on that route today"
          return busout
        end
        # otherwise, print accordingly
        busout += "<br/>The next bus will leave Terminal Station on this route at " + hmarray_to_time(firsttime) + " and reach the event before " + hmarray_to_time(turntime)

        # now find the route of the first leg of the trip - from my closest stop to Terminal Station
        # respect outbound-only bus stop rules
        businbound = "";
        
        if closest.getroute().index("0") == nil  # this route is assigned when none are known
          # look up non-library-connected routes
          sendMeOutbound = 0 # for stops only going outbound
          if closest.hasroute("1") and gotime.wday < 6
            sched = getSchedule("1-W")
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (1) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("2")
            if gotime.wday == 6
              sched = getSchedule("2-S")
            else
              sched = getSchedule("2-W")
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (2) from <i>" + closest.getname() + "</i> to Terminal Station."
          
          elsif closest.hasroute("3")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("3-S")
            else
              # weekday schedule
              sched = getSchedule("3-W")
            end
            if closest.hasroute("3-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (3) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("4")
            if gotime.wday == 6
              sched = getSchedule("4-S")
            else
              sched = getSchedule("4-W")
            end
            if closest.hasroute("4-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (4) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("5")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("5-S")
            else
              # weekday schedule
              sched = getSchedule("5-W")
            end
            if closest.hasroute("5-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (5) from <i>" + closest.getname() + "</i> to Terminal Station."
            
          elsif closest.hasroute("6")
            if gotime.wday == 6
              sched = getSchedule("6-S")
            else
              sched = getSchedule("6-W")
            end
            if closest.hasroute("6-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (6) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("9")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("9-S")
            else
              # weekday schedule
              sched = getSchedule("9-W")
            end
            if closest.hasroute("9-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (9) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("11")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("11-S")
            else
              # weekday schedule
              sched = getSchedule("11-W")
            end
            if closest.hasroute("11-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (11) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("12")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("12-S")
            else
              # weekday schedule
              sched = getSchedule("12-W")
            end
            if closest.hasroute("12-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (12) from <i>" + closest.getname() + "</i> to Terminal Station."

          elsif closest.hasroute("13")
            if gotime.wday == 6
              # Saturday schedule
              sched = getSchedule("13-S")
            else
              # weekday schedule
              sched = getSchedule("13-W")
            end
            if closest.hasroute("13-O")
              sendMeOutbound = 1
            end
            businbound += "<h3>" + address + "</h3>" + bussum + "<br/>Take bus (13) from <i>" + closest.getname() + "</i> to Terminal Station."
          
          end
          
          # 1st leg: find the next bus to arrive at Terminal Station before firsttime of 2nd leg
          dothispass = -1
          sched["times"].reverse_each do |pass|
            pass.reverse_each do |stop|
              if stop != ""
                mylaststop = stop
                break
              end
            end
            if mylaststop[0].to_i * 60 + mylaststop[1].to_i <= firsttime.hour * 60 + firsttime.min
              dothispass = pass
              break
            end
          end
          
          # if their stop is outbound-only, tell them to leave before this bus leaves Terminal Station
          # otherwise (most stops) tell them to leave before bus turns inbound
          if sendMeOutbound == 1
            myfirststop = ""
            dothispass.each do |stop|
              if stop != ""
                myfirststop = stop.split(":")
                break
              end
            end
            businbound += "The next bus leaves Terminal Station on this route at " + hmarray_to_time(myfirststop)
          else
            myturntime = ""
            stopdex = 0
            dothispass.each do |stop|
              if stopdex >= sched["turnaround"] and stop != ""
                myturntime = stop.split(":")
                break
              end
              stopdex = stopdex + 1
            end
            businbound += "The next bus turns inbound on this route at " + hmarray_to_time(myturntime)
          end
          
          # if this first leg of the trip cannot be made, don't print out results
          if dothispass == -1
            return "There are no more buses on that route today"
          end

        else
          # stop has 0 as route number - multiple routes possible?
          businbound += "Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station<br/>"
        end
  
        return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + businbound + "<br/>" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
          
      else
        # not sure - go to Terminal Station
        busout += "<h3>" + address + "</h3>" + bussum + "<br/>Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station."
        return "<!DOCTYPE html>\n<html>\n<head>\n<title>Transit Directions</title>\n</head>\n<body style='font-family:arial;'>\n" + busout + "\n<a href='javascript:history.back()'>&larr; New Address</a></body>\n</html>"
      end
    end
  else
    return "<br/>no address"
  end
end

get '/busnow' do
  erb :busaccuracy
end

get '/wherenow' do
  erb :wherenow
end

get '/wherenow2' do
  erb :wherenow2
end

get '/' do
  erb :maconevent
end

get '/eventsf' do
  erb :transit
end

#get '/search' do
#  @documents = Document.search(params['q'])
#  erb :home
#end
