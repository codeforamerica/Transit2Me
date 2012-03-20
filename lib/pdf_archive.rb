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
end

def closest_macon(lat, lng)
  stations = [
  MaconStop.new("1","MLK and Riverside","0",[-83.621172624935014,32.837522525131753]),
  MaconStop.new("2","Coliseum Drive","0",[-83.618296501092232,32.84122817953682]),
  MaconStop.new("3","Coliseum Drive","0",[-83.618426449057566,32.841512865969698]),
  MaconStop.new("4","Coliseum Drive and Main Street","0",[-83.615983603596817,32.843738014740353]),
  MaconStop.new("5","Main Street and Ft Hill Street","0",[-83.612418461868813,32.845216975004007]),
  MaconStop.new("6","Main Street","0",[-83.608473117977709,32.846632373105905]),
  MaconStop.new("7","Main Street and Leaf Street","0",[-83.61008666847502,32.846021915921149]),
  MaconStop.new("8","Main Street","0",[-83.608501688265534,32.846743676355814]),
  MaconStop.new("9","Main Street","0",[-83.60710924777861,32.847095691002018]),
  MaconStop.new("10","Main Street and Short Street","0",[-83.607469588619239,32.84797435651361]),
  MaconStop.new("11","Emery HWY and Reese Street","0",[-83.604525624419082,32.848368810845798]),
  MaconStop.new("12","Emery Hwy and Lexington Street","0",[-83.617477529087722,32.848278089085611]),
  MaconStop.new("13","Jeffersonville Road and Magnolia Drive SB","0",[-83.600712743781557,32.849623969558856]),
  MaconStop.new("14","Jefersonville Road and Magnolia Drive NB","0",[-83.600728004643784,32.849525215335269]),
  MaconStop.new("15","Jeffersonville Road and Indian Cir","0",[-83.599319834600337,32.850037659726993]),
  MaconStop.new("16","Jeffersonville Road and Dorothy Street","0",[-83.599319284352092,32.85012412710514]),
  MaconStop.new("17","Jeffersonvillle Road and Baker Street NB","0",[-83.59669393038277,32.851026308071518]),
  MaconStop.new("18","Jeffersonville Road and Baker Street SB","0",[-83.596737280067927,32.851112975367883]),
  MaconStop.new("19","Jeffersonville Road and Wallace Drive NB","0",[-83.595182797496122,32.851612352008395]),
  MaconStop.new("20","Jeffersonville Road and Wallace Drive SB","0",[-83.595226067866349,32.851711372797915]),
  MaconStop.new("21","Jeffersonville Road and Artic Circle","0",[-83.591460407038738,32.852410584917713]),
  MaconStop.new("22","Jeffersonville Road and Rowster Drive","0",[-83.590890539038227,32.852272082587675]),
  MaconStop.new("23","Jeffersonville Road and Millerfield Road","0",[-83.588797409705933,32.852324197472129]),
  MaconStop.new("24","Jeffersonville Road and Millerfield Road","0",[-83.588547902389308,32.852434220484611]),
  MaconStop.new("25","Jeffersonville Road and Strozier St NB","0",[-83.587734822870019,32.853690452085274]),
  MaconStop.new("26","Jeffersonville Road and Strozier St SB","0",[-83.587895644132644,32.853715901851324]),
  MaconStop.new("27","Pine Hill Drive","0",[-83.589776818611412,32.861543937528815]),
  MaconStop.new("28","Shurling Drive","0",[-83.592557418727708,32.861593786438107]),
  MaconStop.new("29","E. Pine Hill Drive and New Clinton Road","0",[-83.586312915286541,32.86078674675494]),
  MaconStop.new("30","Lainey Avenue","0",[-83.568451563808665,32.865903151445352]),
  MaconStop.new("31","Donald Avenue and Millerfield Road","0",[-83.582797085199402,32.859028639621123]),
  MaconStop.new("32","Lainey Avenue","0",[-83.569252687005772,32.866487561207371]),
  MaconStop.new("33","Lainey Avenue","0",[-83.570882669522788,32.867891201954521]),
  MaconStop.new("34","","0",[-83.574642898890517,32.868131404267601]),
  MaconStop.new("35","","0",[-83.572537447085239,32.869974343252821]),
  MaconStop.new("36","","0",[-83.571390699887587,32.870722412370341]),
  MaconStop.new("37","Millerfield Road","0",[-83.57068963734956,32.863925030930282]),
  MaconStop.new("38","Millerfield Road and Jordan Avenue","0",[-83.574397452937518,32.861015021940524]),
  MaconStop.new("40","Coliseum Drive and Friendship","0",[-83.616591415871895,32.847211849229346]),
  MaconStop.new("41","Jeffersonville Road and Ocmulgee East BLVD","0",[-83.574193920358368,32.841596989263799]),
  MaconStop.new("42","Jeffersonville Road near Apartments","0",[-83.569513624525257,32.842249935385567]),
  MaconStop.new("43","Jeffersonville Road and Finneydale Drive","0",[-83.562255584103781,32.84195540337636]),
  MaconStop.new("44","Lexington Street and Woolfolk Street","0",[-83.617612120963472,32.849637639948369]),
  MaconStop.new("45","Woolfolk Street and Center Street","0",[-83.615950828163008,32.849630339526662]),
  MaconStop.new("46","Lexington Street and Womack Street","0",[-83.614289374003903,32.849648985553003]),
  MaconStop.new("47","Wolfolk Street and Maynard Street","0",[-83.610997554346241,32.849634411042281]),
  MaconStop.new("48","Jordan Avenue NB","0",[-83.573493067294891,32.855718056612695]),
  MaconStop.new("49","Jordan Avenue SB","0",[-83.573982201051621,32.855454196978478]),
  MaconStop.new("50","Jordan Avenue and Recreation Road","0",[-83.571406976003928,32.853555421738307]),
  MaconStop.new("51","Recreation Road","0",[-83.569318729815478,32.852974154630921]),
  MaconStop.new("52","Recreation Road","0",[-83.567878155221777,32.852162234528564]),
  MaconStop.new("53","Mogul Rd and Jeffersonville Road","0",[-83.557296022631945,32.842634080008345]),
  MaconStop.new("55","Mogule Road and Kings Park Circle","0",[-83.556001368818556,32.846432414896633]),
  MaconStop.new("56","Kings Park Circle","0",[-83.555170980466386,32.845808343818796]),
  MaconStop.new("57","Kings Park Circle","0",[-83.553558986798251,32.847181400377764]),
  MaconStop.new("58","Kings Park Circle","0",[-83.552921550242417,32.847629196484228]),
  MaconStop.new("59","Kings Park Circle","0",[-83.549980654688554,32.848037475667013]),
  MaconStop.new("60","Queens Circle and Masseyville Road","0",[-83.54953785636603,32.849303505841831]),
  MaconStop.new("61","Masseyville Road","0",[-83.55194558334712,32.848751707382164]),
  MaconStop.new("62","Masseyville Road","0",[-83.553585589947062,32.848167919487317]),
  MaconStop.new("63","Masseyville Road and Mogul Raod","0",[-83.555924559934752,32.847897532114317]),
  MaconStop.new("64","Recreation Road and Roseview Drive","0",[-83.586319437075602,32.851840951211173]),
  MaconStop.new("65","Recreation Road","0",[-83.582968486718599,32.85149237991314]),
  MaconStop.new("66","Recreation Road","0",[-83.580477981284488,32.852279899567947]),
  MaconStop.new("67","Recreation Road and Mornigside Road","0",[-83.579175952782094,32.852307091824883]),
  MaconStop.new("68","Morningside Road","0",[-83.57843916833265,32.850372320764784]),
  MaconStop.new("69","Morningside Road and Jeffersonville Road","0",[-83.57943874497208,32.848345809177872]),
  MaconStop.new("70","Jeffersonville Road and McCall Road","0",[-83.579011191815283,32.847378146681386]),
  MaconStop.new("71","Jeffersonville Road","0",[-83.565711479255086,32.842386812442996]),
  MaconStop.new("72","Spring Street and Riverside","0",[-83.630640242107546,32.843091535482621]),
  MaconStop.new("73","1st Street and Cherry Street","0",[-83.630577127167271,32.837339201165783]),
  MaconStop.new("74","Spring Street and Riverside","0",[-83.63037172079791,32.843069768712603]),
  MaconStop.new("75","Emery Highway near Chi-Chesters","0",[-83.624675065895644,32.848096316648657]),
  MaconStop.new("76","Bibb County Health Department","0",[-83.622284700844943,32.847570523620199]),
  MaconStop.new("77","2nd Street near Gray Highway","0",[-83.620739208529656,32.848677090668687]),
  MaconStop.new("78","Hall Street and Lexington Street","0",[-83.617784625989614,32.852519482892205]),
  MaconStop.new("79","Hall Street","0",[-83.616856357825867,32.852536023800063]),
  MaconStop.new("80","Hall Street and Center Street","0",[-83.615976938106215,32.852552773714507]),
  MaconStop.new("81","Hall Street","0",[-83.61517092086973,32.852549223793851]),
  MaconStop.new("82","Emery Highway near Chi-Chesters","0",[-83.625407523289056,32.848140720492921]),
  MaconStop.new("83","Hall Street and Womack Street","0",[-83.614267204289476,32.852545237404186]),
  MaconStop.new("84","Hall Street","0",[-83.613461443225219,32.85250044412026]),
  MaconStop.new("85","Hall Street and Maynard Street","0",[-83.61096973379513,32.852551252840357]),
  MaconStop.new("86","Hall Street","0",[-83.611775878800387,32.852534214104125]),
  MaconStop.new("87","Hall Street and Ft Hill Street","0",[-83.612581895438908,32.852537785892174]),
  MaconStop.new("88","Maynard Street and Taylor Street","0",[-83.610878591954616,32.855416561692344]),
  MaconStop.new("89","Maynard Street and Williams Street","0",[-83.610845296417565,32.856838961987755]),
  MaconStop.new("90","Maynard Street and Morrow Avenue","0",[-83.610787315354813,32.858302485710041]),
  MaconStop.new("91","Maynard Street and Shurling Drive","0",[-83.610756331315514,32.859353795630724]),
  MaconStop.new("92","Shurling Drive and Kitchens Street","0",[-83.607530078892125,32.859648668276357]),
  MaconStop.new("93","Kitchens Street","0",[-83.607381577501783,32.859957253800999]),
  MaconStop.new("94","Haywood Road","0",[-83.606553855377044,32.863396526036041]),
  MaconStop.new("96","Kitchens Street and Haywood Road","0",[-83.607384397885809,32.863400241722069]),
  MaconStop.new("97","Kitchens Street and Haywood Road","0",[-83.604501537926907,32.863449170345639]),
  MaconStop.new("98","Kitchens Street","0",[-83.605054929288684,32.864791734855686]),
  MaconStop.new("99","Kitchens Street","0",[-83.606683707804507,32.866056649246914]),
  MaconStop.new("100","Kitchens Street","0",[-83.607685274425521,32.866061128523654]),
  MaconStop.new("101","Kitchens Street","0",[-83.608210029700132,32.86418736083801]),
  MaconStop.new("102","Kitchens","0",[-83.607487282852304,32.862576037304365]),
  MaconStop.new("103","Shurling Drive and Gray Highway","0",[-83.614736212454048,32.859639432849391]),
  MaconStop.new("104","Shurling Drive and Gray Highway","0",[-83.614979969090101,32.859722973911822]),
  MaconStop.new("105","Shurling Drive and Clinton Road","0",[-83.617789044368607,32.859735329037662]),
  MaconStop.new("108","Clinton Road","0",[-83.615661270889646,32.868055090753977]),
  MaconStop.new("109","Clinton Road","0",[-83.614602263029099,32.869431734066595]),
  MaconStop.new("110","Clinton Road","0",[-83.613296620516323,32.871178375549967]),
  MaconStop.new("112","Gray Highway","0",[-83.612999059986876,32.86402309725225]),
  MaconStop.new("113","Gray Highway","0",[-83.613522796490585,32.862293618808586]),
  MaconStop.new("114","Gray Highway near McAffee Towers","0",[-83.616265151551048,32.85777228053071]),
  MaconStop.new("115","Clinton Road near McAffee Towers","0",[-83.618695390417045,32.857116406710517]),
  MaconStop.new("116","Clinton Road and Curry Place","0",[-83.619135484099431,32.856165386155176]),
  MaconStop.new("117","Clinton Road","0",[-83.619576694073885,32.85503110991052]),
  MaconStop.new("118","Clinton Road","0",[-83.620440679783584,32.852642326644485]),
  MaconStop.new("119","Clinton Road and Gray Highway","0",[-83.620867229168667,32.851348576628517]),
  MaconStop.new("120","Gray Highway","0",[-83.622024164101774,32.850411353597551]),
  MaconStop.new("121","Gray Highway","0",[-83.623353519472005,32.849798772242593]),
  MaconStop.new("122","2nd Street and Mulberry Street","0",[-83.628169073753298,32.837823179083628]),
  MaconStop.new("123","2nd and Cherry Street","0",[-83.629074793336812,32.836563398503287]),
  MaconStop.new("124","Mulberry Street and New Street","0",[-83.630926336350896,32.839814768843212]),
  MaconStop.new("125","Mulberry Street and 1st Street","0",[-83.629435298550632,32.838839560013149]),
  MaconStop.new("126","Spring Street","0",[-83.631964552900527,32.841419862063901]),
  MaconStop.new("127","Sping Street and Walnut Street","0",[-83.631412149444742,32.842007215614849]),
  MaconStop.new("128","Broadway and Oglethorpe Street","0",[-83.631333349184899,32.828398945714198]),
  MaconStop.new("129","Ogletorpe Street and 3rd Street","0",[-83.633160316503918,32.828800163461779]),
  MaconStop.new("130","Ogletorpe Street and 2nd Street","0",[-83.63514175231731,32.829347720458927]),
  MaconStop.new("131","2nd Street and Arch Street","0",[-83.634550812859814,32.83004461790393]),
  MaconStop.new("132","2nd Street and Hemlock Street","0",[-83.63343846024685,32.831351274918681]),
  MaconStop.new("133","2nd Street and Plum Street","0",[-83.63123091658386,32.833964632206289]),
  MaconStop.new("134","2nd and Pine Street","0",[-83.632343247117618,32.832672566531976]),
  MaconStop.new("135","2nd and Arch Street","0",[-83.634480997995695,32.830175460003666]),
  MaconStop.new("136","Broadway and Hazel Street","0",[-83.633784788329706,32.825378634058069]),
  MaconStop.new("137","Broadway and Hawthorne Street","0",[-83.63218552377424,32.827309761338405]),
  MaconStop.new("138","Broadway and Elm Street","0",[-83.635737097702702,32.823093057337942]),
  MaconStop.new("139","Broadway and Edgewood Street","0",[-83.636698943171311,32.821928828844236]),
  MaconStop.new("140","Houston Avenue","0",[-83.637914002408706,32.820782116154376]),
  MaconStop.new("141","Houston Avenue and Wood Street","0",[-83.638579398698226,32.820307729527364]),
  MaconStop.new("142","Houston Avenue and Giles Street","0",[-83.639597403439055,32.819522178987697]),
  MaconStop.new("143","Houston Avenue near Reid Street","0",[-83.64030194892652,32.819015038345974]),
  MaconStop.new("144","Houston Avenue and Jenkins Street","0",[-83.641221618263529,32.818377156120754]),
  MaconStop.new("145","Houston Avenue and Cynthia Avenue","0",[-83.642063133178127,32.817771849011294]),
  MaconStop.new("146","Houston Avenue and Whitehead Street","0",[-83.642866145747718,32.817084100426094]),
  MaconStop.new("147","Houston Avenue and Ell Street","0",[-83.64353245251182,32.816445140533382]),
  MaconStop.new("148","Houston Avenue and Ell Street Lane","0",[-83.644099389321369,32.815681434993905]),
  MaconStop.new("149","Houston Avenue and Eisenhower Parkway","0",[-83.64476893934237,32.814028946879986]),
  MaconStop.new("150","Houston Avenue and Central Avenue","0",[-83.645005757683165,32.813357988852538]),
  MaconStop.new("151","Houston Avenue and Second Street","0",[-83.645693053451808,32.811984180713317]),
  MaconStop.new("152","Houston Avenue and Nelson Street","0",[-83.646439409085446,32.810463114278363]),
  MaconStop.new("153","Houston Avenue and Cleavland Street","0",[-83.647362304449118,32.808614995499738]),
  MaconStop.new("154","Houston Avenue and Rutherford Avenue","0",[-83.647911875290546,32.807551993279766]),
  MaconStop.new("155","Housotn Avenue and Lackey Drive","0",[-83.648598890483115,32.806210944128708]),
  MaconStop.new("156","Houston Avenue and Quinlan Drive","0",[-83.649207598351381,32.804984290788823]),
  MaconStop.new("157","Houston Avenue and Heard Avenue","0",[-83.650326516200849,32.802776401592801]),
  MaconStop.new("158","Houston Avenue near Villa Crest","0",[-83.650738759903831,32.801958652762188]),
  MaconStop.new("159","Houston Avenue and W. Greenada Terrace","0",[-83.651504347533233,32.800437631050315]),
  MaconStop.new("160","Houston Avenue and W. Ormand Terrace","0",[-83.652054195302242,32.799309053952527]),
  MaconStop.new("161","Houston Avenue and Villa Esta","0",[-83.652662996190344,32.798049603455262]),
  MaconStop.new("162","Houston Avenue and Lynmore Street","0",[-83.65309488289212,32.797182760598076]),
  MaconStop.new("164","Houston Avenue and Grady Street","0",[-83.655077871121307,32.793142799025055]),
  MaconStop.new("165","Houston Avenue and Fulton Street","0",[-83.655706364129642,32.791817857377019]),
  MaconStop.new("166","Houston Avenue and Buena Vista Avenue","0",[-83.657803192718433,32.788188037284229]),
  MaconStop.new("167","Houston Avenue and Green Street","0",[-83.658156999044223,32.787386412936755]),
  MaconStop.new("168","Houston Avenue and Chattam Street","0",[-83.658452035539625,32.786682883965078]),
  MaconStop.new("169","Chattam Street","0",[-83.657772974083471,32.78668012691395]),
  MaconStop.new("170","Chattam Street and Capital Avenue","0",[-83.65587169317736,32.786655998951538]),
  MaconStop.new("171","Houston Avenue amd Putnam Street","0",[-83.658998038932026,32.782784513746797]),
  MaconStop.new("173","Marion Avenue","0",[-83.64669642447214,32.789681323094214]),
  MaconStop.new("174","Marion Avenue and Shi Place","0",[-84.1666666666667,-90.0]),
  MaconStop.new("175","Marion Avenue and Carmen Place","0",[-83.64997683779734,32.784366548841021]),
  MaconStop.new("176","Marion Avenue and Shi Place","0",[-83.6497529053797,32.783340607763712]),
  MaconStop.new("177","San Carlos Place","0",[-83.642902843599032,32.790163056034125]),
  MaconStop.new("178","San Carlos Drive and Melvin Place","0",[-83.642915410191236,32.788018933523972]),
  MaconStop.new("179","Albert Street and San Carlos Drive","0",[-83.642990958049083,32.785692034317677]),
  MaconStop.new("180","Mead Road","0",[-83.639788107973885,32.78813655977217]),
  MaconStop.new("181","Mead Road","0",[-83.640300495507006,32.790492076805705]),
  MaconStop.new("182","2nd Street and Hawthorne Street","6",[-83.635789804258266,32.82814965688938]),
  MaconStop.new("183","2nd Street near Cynthia Avenue","6",[-83.644451242055752,32.819241328034707]),
  MaconStop.new("184","2nd Street and Anderson Street","6",[-83.642133783963061,32.820868590438828]),
  MaconStop.new("185","2nd Street and Wood Street","6",[-83.641182160211414,32.821780512192568]),
  MaconStop.new("186","2nd Street and Prince Street","6",[-83.640461310641257,32.822693396712729]),
  MaconStop.new("187","2nd Street and Edgewood Avenue","6",[-83.639601507450763,32.823683642388012]),
  MaconStop.new("188","2nd Street and Elm Street","6",[-83.638533160917433,32.824809413976269]),
  MaconStop.new("189","2nd Street and Ash Street","6",[-83.63744055168452,32.826129949180142]),
  MaconStop.new("190","2nd Street and Hazel Street","6",[-83.636626843247683,32.827120368356731]),
  MaconStop.new("191","2nd Street near Wyche Street","6",[-83.645354485826118,32.818699441142904]),
  MaconStop.new("192","2nd Street and Bowden Street","6",[-83.646142328664141,32.818157068772997]),
  MaconStop.new("193","2nd Street","6",[-83.646122432523896,32.817611335496771]),
  MaconStop.new("194","Ell Street","6",[-83.647144668477992,32.816446330584945]),
  MaconStop.new("195","2nd Street and Ell Street","6",[-83.64622144712655,32.816461983609123]),
  MaconStop.new("196","Ell Street and Felton Avenue","6",[-83.649475401670941,32.816475467932129]),
  MaconStop.new("197","A Street","6",[-83.652253708991736,32.814927911120257]),
  MaconStop.new("198","A Street and B Street","6",[-83.653775355727277,32.81518749149393]),
  MaconStop.new("199","A Street and Ell Street","6",[-83.654575462970996,32.816515919765017]),
  MaconStop.new("200","A Street","6",[-83.654861110700779,32.814997059310187]),
  MaconStop.new("201","Ell Street and Goodwin Street","6",[-83.657552268951747,32.816567035136323]),
  MaconStop.new("204","Pio Nono and Holley Street","6",[-83.662846094271131,32.814990471342249]),
  MaconStop.new("205","Ell Street and Adams Street","6",[-83.661105912499238,32.81663989783987]),
  MaconStop.new("206","Ell Street and Monroe Avenue","6",[-83.660275222978939,32.816617053237309]),
  MaconStop.new("208","Pio Nono Avenue near Home Depot","6",[-83.663041046642689,32.813159424887353]),
  MaconStop.new("209","Pio Nono Avenue and Hightower Road","6",[-83.663120498052322,32.811347401464793]),
  MaconStop.new("210","Pio Nono Avenue and  Rice Mill Road","6",[-83.662996769857969,32.808735569478884]),
  MaconStop.new("211","Pio Nono Avenue and Williamson Road","6",[-83.663104127020148,32.806066203401741]),
  MaconStop.new("212","Pio Nono Avenue and Newburg Avenue","6",[-83.663285313300108,32.802578653743552]),
  MaconStop.new("213","Pio Nono Avenue and Spencer Circle","6",[-83.665614919686107,32.79863201405302]),
  MaconStop.new("214","Pio Nono Avenue and Sherry Drive","6",[-83.664123986792418,32.801159427856156]),
  MaconStop.new("215","Pio Nono Avenue near Spencer Circle","6",[-83.665524047695484,32.798378311045155]),
  MaconStop.new("216","Pio Nono Avenue and South Plaza Shopping Center","6",[-83.667875972750423,32.794529152394681]),
  MaconStop.new("217","Pio Nono Avenue and South Plaza Shopping Center","6",[-83.667692919524924,32.794255597004941]),
  MaconStop.new("218","Pio Nono Avenue and Rocky Creek Road","6",[-83.668585407736529,32.791433443462552]),
  MaconStop.new("219","Rocky Creek Road","6",[-83.671678689615931,32.79113390414031]),
  MaconStop.new("220","Rocky Creek Road","6",[-83.672467099386978,32.790415974912435]),
  MaconStop.new("221","Rocky Creek Road","6",[-83.673930353621316,32.788648364284398]),
  MaconStop.new("222","Rocky Creek Road and South View Drive","6",[-83.678054286931228,32.785488031411504]),
  MaconStop.new("224","Rocky Creek Road and Bloomfield Drive","6",[-83.688296869003381,32.785605517219651]),
  MaconStop.new("225","Rocky Creek Road and Bloomfield Drive","6",[-83.688574436654648,32.78547016302204]),
  MaconStop.new("227","Rocky Creek Road and Thrasher Avenue","6",[-83.698513763927394,32.786228749495798]),
  MaconStop.new("228","Rocky Creek Road Bethesda Avenue","6",[-83.702895154546013,32.786615315226285]),
  MaconStop.new("229","Rocky Creek Plaza","6",[-83.706561505994841,32.786979614862688]),
  MaconStop.new("230","Debb Drive and Deborah Drive","6",[-83.710628836783783,32.785630350204158]),
  MaconStop.new("231","Debb Drive and Federica Place","6",[-83.709752279025324,32.785607668216272]),
  MaconStop.new("232","Debb Drive and Sterling Place","6",[-83.711551534721451,32.785653193712918]),
  MaconStop.new("233","Debb Drive","6",[-83.712428193645948,32.785656375877586]),
  MaconStop.new("234","Debb Drive","6",[-83.713696942249427,32.785680458018355]),
  MaconStop.new("235","Debb Drive","6",[-83.715057971109175,32.785704860050437]),
  MaconStop.new("236","Debb Drive","6",[-83.717642005032246,32.785675174618042]),
  MaconStop.new("237","Debb Drive","6",[-83.716816292119503,32.784717313666143]),
  MaconStop.new("238","Bloomfield Road and Anderson Drive","6",[-83.707685745098814,32.788191975551413]),
  MaconStop.new("239","Bloomfield Road and Wallace Drive","6",[-83.707679439586954,32.789419676774955]),
  MaconStop.new("240","Bloomfield Road and Robinhood Road","6",[-83.707585898704139,32.794154839818091]),
  MaconStop.new("241","Bloomfield Road and Greenwod Road","6",[-83.707568633238878,32.793024491906309]),
  MaconStop.new("242","Bloomfield Road","6",[-83.707533745089975,32.795323909091351]),
  MaconStop.new("243","Bloomfield Road and Pine Forest Road","6",[-83.707449603232504,32.798227262761102]),
  MaconStop.new("244","1st Street and Walnut Street","5",[-83.628192608366845,32.840139073649155]),
  MaconStop.new("245","Riverside Drive and Spring Street","5",[-83.630810408201043,32.843673315638561]),
  MaconStop.new("246","Riverside Drive near Spring Street","5",[-83.630569576184783,32.843326244868763]),
  MaconStop.new("247","Riverside Drive near Franklin Street","5",[-83.631612057956204,32.84417657882755]),
  MaconStop.new("248","Riverside Drive and Franklin Street","5",[-83.632021974981015,32.844178330768962]),
  MaconStop.new("249","Riverside Drive and Jones Street","5",[-83.632703747963149,32.844808626121612]),
  MaconStop.new("250","Riverside Drive near Orange Street","5",[-83.634233208118033,32.84591533512824]),
  MaconStop.new("251","Riverside Drive and College Street","5",[-83.635834982762404,32.846609760159431]),
  MaconStop.new("252","Riverside Drive and Madison Street","5",[-83.637436900251828,32.847284518428083]),
  MaconStop.new("253","Madison Street and Walnut Street","5",[-83.63823868809709,32.845519740910213]),
  MaconStop.new("254","Walnut Street","5",[-83.639725049067508,32.846056457897582]),
  MaconStop.new("255","Walnut Street","5",[-83.640159282033309,32.846324876054361]),
  MaconStop.new("256","Walnut Street near Eastern side of I-75","5",[-83.641591021548678,32.847084510254518]),
  MaconStop.new("257","Walnut Street near Western side of I-75","5",[-83.642618296306111,32.847318178972195]),
  MaconStop.new("258","Walnut Street and Moughan Street","5",[-83.646417777381032,32.848104033869021]),
  MaconStop.new("259","Walnut Street and Ward Street","5",[-83.647930568931969,32.848290527289663]),
  MaconStop.new("260","Walnut Street and Giant Avenue","5",[-83.647135117314761,32.848238078830462]),
  MaconStop.new("261","Pierce Avenue near Riverside Drive","5",[-83.662347728269083,32.872369235779054]),
  MaconStop.new("262","Riverside Drive near Wimbish Road","5",[-83.672875923805847,32.885469200861557]),
  MaconStop.new("263","Riverside Drive near Northside Drive","5",[-83.677070392926822,32.890632295456122]),
  MaconStop.new("264","Ward Street and 3rd Avenue","5",[-83.648521997022073,32.84685373650121]),
  MaconStop.new("265","Ward Street and Forest Avenue","5",[-83.649606407126711,32.847210959821645]),
  MaconStop.new("266","3rd Avenue and Moughan Street","5",[-83.647020040251761,32.846441859037014]),
  MaconStop.new("267","3rd Avenue and Pursley Street","5",[-83.645936062116562,32.846014066687253]),
  MaconStop.new("268","3rd Avenue and 4th Street","5",[-83.643538730173887,32.845086948587486]),
  MaconStop.new("269","3rd Avenue near Empire Street","5",[-83.645332429952148,32.845623541706331]),
  MaconStop.new("270","4th Street and 2nd Avenue","5",[-83.644151445994439,32.84392547225557]),
  MaconStop.new("271","2nd Avenue","5",[-83.645465519445906,32.844301326926868]),
  MaconStop.new("272","2nd Avenue and Pursley Street","5",[-83.646800393072155,32.844694892052836]),
  MaconStop.new("273","Ward Street and 2nd Street","5",[-83.64909420540134,32.845462787646468]),
  MaconStop.new("274","Sycamore Street and Walnut Street","5",[-83.652817189238505,32.848405859359829]),
  MaconStop.new("275","Clayton Street and Rogers Avenue","5",[-83.655258620108981,32.848962605671353]),
  MaconStop.new("276","Rogers Avenue","5",[-83.65525325841395,32.849897340191156]),
  MaconStop.new("277","Rogers Avenue and Neal Avenue","5",[-83.655183291105814,32.851166912362686]),
  MaconStop.new("278","Rogers Avenue and Rogers Place","5",[-83.654586902662047,32.853139807344427]),
  MaconStop.new("279","Rogers Avenue and Ingleside Avenue","5",[-83.654353510999343,32.853756142928326]),
  MaconStop.new("280","Ingleside Avenue","5",[-83.64730542929415,32.854838211545015]),
  MaconStop.new("281","Ingleside Avenue and Riverside Drive","5",[-83.645085478712588,32.855693184722767]),
  MaconStop.new("282","Riverside Drive near Bibb Co Vocational Complex","5",[-83.643859890524766,32.854453488064735]),
  MaconStop.new("283","Baxter Avenue and North Brook","5",[-83.643306594077387,32.852599300768283]),
  MaconStop.new("284","Baxter Avenue and Mallory Drive","5",[-83.644562032027437,32.852304717705493]),
  MaconStop.new("285","Forest Avenue","5",[-83.646547124151908,32.852295348025251]),
  MaconStop.new("286","Forest Avenue and Sherman Avenue","5",[-83.648054385235966,32.849952072423434]),
  MaconStop.new("287","Forest Avenue and Walnut Street","5",[-83.648983973730935,32.848443411781396]),
  MaconStop.new("288","Pierce Avenue","5",[-83.66215510855973,32.86057627870796]),
  MaconStop.new("289","Pierce Avenue and Old Horton Road","5",[-83.661556926965488,32.865111388607353]),
  MaconStop.new("290","Pierce Avenue","5",[-83.662265326982535,32.867488041755777]),
  MaconStop.new("291","Pierce Avenue and Sheffield Road","5",[-83.662394225876724,32.871101770903287]),
  MaconStop.new("292","Riverside Drive and Burrus Road","5",[-83.663866558309735,32.874867954389373]),
  MaconStop.new("293","Riverside Drive and Lee Road","5",[-83.666265666174837,32.877650500575278]),
  MaconStop.new("294","Riverside Drive","5",[-83.667055453637985,32.878872064383323]),
  MaconStop.new("295","Riverside Drive near Thornwood Drive","5",[-83.668836606513437,32.880895839018763]),
  MaconStop.new("296","Riverside Drive near Wimbish Road","5",[-83.673164193253413,32.886164738475195]),
  MaconStop.new("297","Riverside Drive","5",[-83.674401138988998,32.887598088892496]),
  MaconStop.new("298","Riverside Drive near Northside Drive","5",[-83.676874107143249,32.890653811347661]),
  MaconStop.new("299","Northside Drive near North Ingle Place","5",[-83.677744042884385,32.890930306520389]),
  MaconStop.new("300","Northside Drive","5",[-83.679855450890244,32.891841843474843]),
  MaconStop.new("301","Northside Drive and Holiday Drive North","5",[-83.687307577103397,32.895105707523463]),
  MaconStop.new("302","Northside Drive and Tom Hill Sr BLVD","5",[-83.690188488163187,32.896503178797957]),
  MaconStop.new("303","Tom Hill Sr and Riverside Drive","5",[-83.686803226540107,32.900901695993753]),
  MaconStop.new("304","Riverside Drive and Holiday Drive","5",[-83.685785803232889,32.900246571414193]),
  MaconStop.new("305","Riverside Drive","5",[-83.684519729672076,32.899527459007452]),
  MaconStop.new("306","Riverside Drive near SS Office","5",[-83.683776813787674,32.898768341920665]),
  MaconStop.new("307","Riverside Drive","5",[-83.67915047002694,32.893267571659841]),
  MaconStop.new("308","Ingleside Avenue and Corbin Avenue","5",[-83.657490085787927,32.853733514457502]),
  MaconStop.new("309","Ingleside Avenue","5",[-83.65653867698127,32.853747483527378]),
  MaconStop.new("310","Ingleside Avenue and Bufford Place","5",[-83.660428466322756,32.853763281526525]),
  MaconStop.new("311","Ingleside Avenue and Pierce Avenue","5",[-83.662436581365995,32.853807077660782]),
  MaconStop.new("312","1st Street and Plum Street","9",[-83.63267959688541,32.834914451845513]),
  MaconStop.new("313","1st Street and Pine Street","9",[-83.633877228247201,32.833598891830768]),
  MaconStop.new("314","2nd Street and Pine Street","12",[-83.632537844948601,32.83283054674056]),
  MaconStop.new("315","1st Street and Hemlock Street","9",[-83.635008730218829,32.832283039896865]),
  MaconStop.new("316","1st Street and Hemlock Street","9",[-83.635053901911732,32.832097222566027]),
  MaconStop.new("317","1st Street and Arch Street","9",[-83.636052072215051,32.830966802662303]),
  MaconStop.new("318","1st Street and Arch Street","9",[-83.636162007771276,32.831004470498321]),
  MaconStop.new("319","Telfair Street and Hawthorne Street","9",[-83.63945819706224,32.828730484526233]),
  MaconStop.new("320","Telfair Street near Hazel Street","9",[-83.639745146816665,32.828638688097357]),
  MaconStop.new("321","Telfair Street and Ash Street","9",[-83.640433694786225,32.827692937720798]),
  MaconStop.new("322","Telfair Street and Elm Street","9",[-83.641409827746912,32.826543780009835]),
  MaconStop.new("323","Telfair Street near RR Crossing","9",[-83.642097029651879,32.825821225686937]),
  MaconStop.new("324","Telfair Street and Prince Street","9",[-83.643383500194147,32.824338534924188]),
  MaconStop.new("325","Telfair Street near Pebble Street","9",[-83.643739463735429,32.823744792770555]),
  MaconStop.new("326","Jeff Davis Street and Curd Street","9",[-83.64524486511533,32.822486207904909]),
  MaconStop.new("327","Jeff Davis Street and Williams Street","9",[-83.646107695038225,32.821857366035701]),
  MaconStop.new("328","Jeff Davis Street and Emory Street","9",[-83.646659448582469,32.82146576091926]),
  MaconStop.new("329","Jeff Davis Street near Harold Street","9",[-83.647566594399819,32.820802161584815]),
  MaconStop.new("330","Jeff Davis Street and Alley","9",[-83.648317926534375,32.820233247336219]),
  MaconStop.new("331","Felton Avenue near Jeff Davis Street","9",[-83.649319834162853,32.820261226591036]),
  MaconStop.new("332","Felton Avenue","9",[-83.649316656790958,32.820809406009452]),
  MaconStop.new("333","Felton Avenue","9",[-83.64932780085833,32.821321891782532]),
  MaconStop.new("334","Felton Avenue","9",[-83.649275235874626,32.823085423467084]),
  MaconStop.new("335","Felton Avenue","9",[-83.649309611015212,32.822024932661975]),
  MaconStop.new("336","Felton Avenue and Plant Street","9",[-83.649213253208472,32.824038544373991]),
  MaconStop.new("337","Plant Street and Little Richard Penniman","9",[-83.651079732967361,32.825893413847055]),
  MaconStop.new("338","Little Richard Penniman","9",[-83.651602785205014,32.825752560554925]),
  MaconStop.new("339","Little Richard Penniman","9",[-83.652548368015715,32.825768365558183]),
  MaconStop.new("340","Little Richard Penniman and Stadium Drive","9",[-83.653479905857949,32.825772187952893]),
  MaconStop.new("341","Mercer University BLVDand Canton Road","9",[-83.654044747832771,32.825726833448947]),
  MaconStop.new("342","Mercer University BLVD","9",[-83.659365532798191,32.825796178277827]),
  MaconStop.new("343","Mercer University BLVD and Madden Avenue","9",[-83.660438078410465,32.825824354242442]),
  MaconStop.new("344","Mercer University Blvd near Pio Nono Avenue","9",[-83.661518728607632,32.825806209561584]),
  MaconStop.new("345","Pio Nono Avenue near Mercer University Blvd","9",[-83.662724339805749,32.825599206960092]),
  MaconStop.new("346","Pio Nono Avenue","9",[-83.662680018222972,32.824560906243448]),
  MaconStop.new("347","Pio Nono Avenue near Vining Circle","9",[-83.662775304009912,32.823420286201006]),
  MaconStop.new("348","Pio Nono Avenue and Stephens Street","9",[-83.662688328684752,32.822090291936249]),
  MaconStop.new("349","Pio Nono Avenue and Aline Street","9",[-83.662853004549177,32.820814496341875]),
  MaconStop.new("350","Anthony Road and Cedar Avenue","9",[-83.664494116473875,32.820209453250584]),
  MaconStop.new("351","Anthony Road and Anthony Terrace","9",[-83.667801077866912,32.820196082074517]),
  MaconStop.new("353","Eisnhower Parkway and Anthony Terrace","9",[-83.667611845298808,32.814610815800144]),
  MaconStop.new("354","Eisenhower Parkyway near Pio Nono Avenue","9",[-83.663392586442328,32.814487555540204]),
  MaconStop.new("355","Eisenhower Parkway","9",[-83.669815953706433,32.814672768045845]),
  MaconStop.new("356","Eisenhower Parkway and Key Street","9",[-83.675295189334719,32.814747578022946]),
  MaconStop.new("357","Eisenhower Parkway and Heron Street","9",[-83.679545974553747,32.814870559955679]),
  MaconStop.new("358","Eisenhower Parkway and Oglesby Place","9",[-83.685086067989928,32.815344072845164]),
  MaconStop.new("359","Eisenhower Parkway near Macon Mall","9",[-83.690438263427737,32.815630474360923]),
  MaconStop.new("360","Eisenhower Parkway near Macon Mall","9",[-83.691257904268568,32.815474031863651]),
  MaconStop.new("361","Eisenhower Parkway","9",[-83.685594751285322,32.815183146117889]),
  MaconStop.new("362","Eisenhower Parkway and Bloomfield Road","9",[-83.698896910054501,32.815831893436162]),
  MaconStop.new("363","Bloomfield Road","9",[-83.70001717176271,32.81383176534537]),
  MaconStop.new("364","Bloomfield Road and Jackson Street","9",[-83.701028920850661,32.812872049587689]),
  MaconStop.new("365","Bloomfield Road and Walker Avenue","9",[-83.702152075416805,32.811869891479759]),
  MaconStop.new("366","Bloomfield Road","9",[-83.703896431631804,32.810258718479815]),
  MaconStop.new("367","Bloomfield Road","9",[-83.704944994843686,32.809343192499412]),
  MaconStop.new("368","Bloomfield Road","9",[-83.70650323625793,32.807529090622623]),
  MaconStop.new("369","Bloomfield Road and Chambers Road","9",[-83.707496842669684,32.80637638265928]),
  MaconStop.new("375","Chambers Road","9",[-83.719864526878567,32.806496949973095]),
  MaconStop.new("376","Macon State College","9",[-83.729056595389835,32.808785255832021]),
  MaconStop.new("377","Oglethorpe Street and Second Street","3",[-83.637743963052984,32.830036356570098]),
  MaconStop.new("378","Oglethorpe Street and Lee Street","3",[-83.639642598931275,32.830691659736594]),
  MaconStop.new("379","Oglethorpe Street and Calhoun Street","3",[-83.641340189395009,32.831737664173588]),
  MaconStop.new("380","Oglethorpe Street and Appleton Street","3",[-83.642811780099322,32.832590909418968]),
  MaconStop.new("381","College Street near Tatnall Square Park","3",[-83.645021041528125,32.833559090959255]),
  MaconStop.new("382","Coleman Avenue and Adams Street","3",[-83.649000943247913,32.832808450355031]),
  MaconStop.new("383","Montpelier Avenue near I-75","3",[-83.653109060343866,32.83279340816383]),
  MaconStop.new("384","Montpelier Avenue and Duncan Avenue","3",[-83.654396523411776,32.832766718749035]),
  MaconStop.new("385","Montpelier Avenue and Oakland Avenue","3",[-83.656119662642027,32.832693846490429]),
  MaconStop.new("386","Montpelier Avenue and Pio Nono Avenue","3",[-83.66200896728499,32.832382095080753]),
  MaconStop.new("387","Montpelier Avenue and Courtland Street","3",[-83.664095015112338,32.831735202173817]),
  MaconStop.new("388","Montpelier Avenue near Old Miller School","3",[-83.659319109570902,32.832674890703288]),
  MaconStop.new("389","Montpelier Avenue and Patterson Street","3",[-83.660606024932889,32.832744031012496]),
  MaconStop.new("390","Montpelier Avenue and Blossom Street","3",[-83.666085844182376,32.831183787590604]),
  MaconStop.new("391","Montpelier Avenue and Vinton Avenue","3",[-83.667204250729128,32.830916550737122]),
  MaconStop.new("392","Montpelier Avenue and Poppy Avenue","3",[-83.666882616017034,32.830883302512248]),
  MaconStop.new("393","Montpelier Avenue and Brebtwood Avenue","3",[-83.668398728514305,32.830585676969527]),
  MaconStop.new("394","Montpelier Avenue","3",[-83.665137893610208,32.831435715305886]),
  MaconStop.new("395","Montpelier Avenue","3",[-83.669764013171005,32.830175556187555]),
  MaconStop.new("396","Montpelier Avenue and Buena Vista","3",[-83.671053211331781,32.82982904981079]),
  MaconStop.new("397","Montpelier Avenue and Helon Street","3",[-83.673272174716985,32.82908663230225]),
  MaconStop.new("398","Montpelier Avenue and Bailey Street","3",[-83.674278101791032,32.828611114291206]),
  MaconStop.new("399","Montpelier Avenue","3",[-83.675284899408098,32.827975765750622]),
  MaconStop.new("400","Montpelier Avenue and Mercer University Drive","3",[-83.676977440985638,32.82655994391434]),
  MaconStop.new("401","Mercer University Drive and Well Worth Avenue","3",[-83.679655284654956,32.82495614357142]),
  MaconStop.new("402","Mercer University Drive and Anthony Road","3",[-83.68164890806618,32.823845098690754]),
  MaconStop.new("403","Anthony Road near Mercer University Drive","3",[-83.681574410164572,32.823621052454264]),
  MaconStop.new("404","Anthony Road and Swan Drive","3",[-83.680159374582217,32.822768481165021]),
  MaconStop.new("405","Swan Drive","3",[-83.680711956233935,32.822099355497237]),
  MaconStop.new("406","Swan Drive","3",[-83.680943359230611,32.821317104062004]),
  MaconStop.new("407","Swan Drive","3",[-83.680040556192225,32.820258742263526]),
  MaconStop.new("408","Swan Drive","3",[-83.680083465558468,32.819331914681591]),
  MaconStop.new("409","Wren Avenue","3",[-83.680963101152813,32.817689116741455]),
  MaconStop.new("410","Wren Avenue","3",[-83.679600499881914,32.817651857661126]),
  MaconStop.new("411","Wren Avenue","3",[-83.67925928174111,32.817746425895116]),
  MaconStop.new("412","Wren Avenue","3",[-83.680856146615142,32.81647401924873]),
  MaconStop.new("413","Wren Avenue","3",[-83.677366186506973,32.817802971344811]),
  MaconStop.new("414","Heron Street","3",[-83.679477078420405,32.815989180293656]),
  MaconStop.new("415","Wren Avenue","3",[-83.676700830684211,32.818327797617876]),
  MaconStop.new("416","Wren Avenue","3",[-83.676371424393523,32.819716998960629]),
  MaconStop.new("417","Key Street","3",[-83.674608578283994,32.820173579199071]),
  MaconStop.new("418","Key Street","3",[-83.675398962450998,32.817571510618855]),
  MaconStop.new("419","Mercer University Drive and Selma Street","3",[-83.682825610617328,32.823274276438774]),
  MaconStop.new("420","Mercer University Drive and Oglesby Place","3",[-83.685142061397116,32.821956647954146]),
  MaconStop.new("421","Mercer University Drive and Edna Place","3",[-83.689274686907098,32.820805740889625]),
  MaconStop.new("422","Mercer University Drive near the Mall","3",[-83.69344082656427,32.820453956736976]),
  MaconStop.new("423","Mercer University Drive and Northwoods Drive","3",[-83.699486851693749,32.822570395486871]),
  MaconStop.new("424","Mercer University Drive","3",[-83.702150285117298,32.823635162576998]),
  MaconStop.new("425","Mercer University Drive and Bloomfield Road","3",[-83.695784787385691,32.82105415379727]),
  MaconStop.new("426","Mercer University Drive","3",[-83.696861339064242,32.82150571329386]),
  MaconStop.new("427","Mercer Univeristy Drive","3",[-83.705891416052509,32.824959567876839]),
  MaconStop.new("428","Mercer University Drive","3",[-83.706761493527679,32.825090629107706]),
  MaconStop.new("429","Mercer University Drive","3",[-83.708539104499494,32.825432783618155]),
  MaconStop.new("430","Mercer University Drive and Log Cabin Drive","3",[-83.709446558920476,32.825659858336415]),
  MaconStop.new("431","Mercer University Drive and Columbus Road","3",[-83.714139708739154,32.825932634443902]),
  MaconStop.new("432","Mercer University Drive and West Drive","3",[-83.71652125156308,32.826644459436608]),
  MaconStop.new("433","Mercer University and Ebenezer Church Road","3",[-83.71657884666557,32.826484839436461]),
  MaconStop.new("434","Mercer University Drive near Vallie Drive","3",[-83.711434289312066,32.825635137283001]),
  MaconStop.new("435","Mercer University Drive and West Oak Court","3",[-83.720170396457434,32.827504610109379]),
  MaconStop.new("436","Mercer University Drive and West Oak Drive","3",[-83.721755864191067,32.828437250731923]),
  MaconStop.new("437","Mercer University Drive and Emory Greene Drive","3",[-83.727173930115526,32.831461134226473]),
  MaconStop.new("438","Mercer University Drive and Macon West Drive","3",[-83.725283965132903,32.83083115976418]),
  MaconStop.new("439","Mercer University Drive and Woodfield Drive","3",[-83.723132658193208,32.829465027419957]),
  MaconStop.new("440","Mercer University Drive and Tucker Valley Road","3",[-83.731635137356392,32.832787298277161]),
  MaconStop.new("441","Mercer University Drive near I-475","3",[-83.735795665184924,32.833680736295953]),
  MaconStop.new("442","Mercer University Drive near McManus Drive","3",[-83.737745096232899,32.833783328129364]),
  MaconStop.new("443","Mercer University Drive and Knight Road","3",[-83.740962529384149,32.833970121813678]),
  MaconStop.new("444","Mercer University Drive near Food Lion","3",[-83.743347616502476,32.834026158818368]),
  MaconStop.new("445","Vineville Avenue and Craft Street","1",[-83.646861226907276,32.841141078364707]),
  MaconStop.new("447","Washington Street and College Street","1",[-83.638700231114413,32.83918129019937]),
  MaconStop.new("448","Vineville Avenue and Holt Avenue","1",[-83.64999827370255,32.84202123883788]),
  MaconStop.new("449","Vineville Avenue and Ward Street","1",[-83.650675694537654,32.842432112963373]),
  MaconStop.new("450","Vineville Avenue","1",[-83.652060399900449,32.843317736636237]),
  MaconStop.new("451","Vineville Avenue and Lamar Street","1",[-83.653294433045289,32.844138965232453]),
  MaconStop.new("452","Vineville Avenue and Culver Street","1",[-83.654559142885063,32.844883791643241]),
  MaconStop.new("453","Vineville Avenue and Rogers Avenue","1",[-83.655552606759755,32.845512725284777]),
  MaconStop.new("454","Vineville Avenue and Corbin Avenue","1",[-83.657300923864156,32.846233993437359]),
  MaconStop.new("455","Vineville Avenue and Calloway Drive","1",[-83.658222087086656,32.846301502210324]),
  MaconStop.new("456","Vinevile Avenue and Buford Place","1",[-83.659400723589982,32.846255275691178]),
  MaconStop.new("457","Vineville Avenue and Hines Place","1",[-83.660700287953972,32.846196774157974]),
  MaconStop.new("458","Vineville Avenue and Stonewall Place","1",[-83.663994619189353,32.846031515234642]),
  MaconStop.new("459","Vineville Avenue and Holmes Avenue","1",[-83.665036786039835,32.846073954952033]),
  MaconStop.new("460","Vineville Avenue and Desoto Place","1",[-83.667204918942844,32.846365940644084]),
  MaconStop.new("461","Vineville Avenue @ Blind Academy","1",[-83.669157884562836,32.847155436632065]),
  MaconStop.new("462","Vineville Avenue and Kenmore Place","1",[-83.671446352634916,32.848177192168755]),
  MaconStop.new("463","Vineville Avenue and Speer Street","1",[-83.672181223158461,32.848499891148862]),
  MaconStop.new("464","Vineville Avenue and Vista Drive","1",[-83.67335455044973,32.849463900907651]),
  MaconStop.new("465","Vineville Avenue and Hartley Avenue","1",[-83.674443417559786,32.850480866860906]),
  MaconStop.new("466","Vineville Avenue and Marshall Avenue","1",[-83.675553749309003,32.851426842284766]),
  MaconStop.new("467","Vineville Avenue","1",[-83.67664305713015,32.852372725511863]),
  MaconStop.new("468","Vineville Avenue","1",[-83.678046552156658,32.853604086690147]),
  MaconStop.new("469","Vineville Avenue near Brookdale Avenue","1",[-83.678716984356242,32.854175224138856]),
  MaconStop.new("470","Vineville Avenue","1",[-83.681125456101412,32.856405376671056]),
  MaconStop.new("471","Vineville Avenue and Prentice Place","1",[-83.681690780649006,32.856958323464525]),
  MaconStop.new("472","Vineville Avenue and Auburn Avenue","1",[-83.68273783197121,32.857957289098913]),
  MaconStop.new("473","Vineville Avenue and Belvedere","1",[-83.683198507629939,32.858403226399695]),
  MaconStop.new("474","Vineville Avenue and Albermarle","1",[-83.683994151957108,32.859188014064884]),
  MaconStop.new("475","Ridge Avenue and Ingleside Avenue","1",[-83.678642848443474,32.856182523235994]),
  MaconStop.new("476","Vineville Avenue and Riverdale Drive","1",[-83.68485296033991,32.859973039910287]),
  MaconStop.new("477","Ridge Avenue","1",[-83.677701204428146,32.855166169519848]),
  MaconStop.new("479","Ridge Avenue and Auburn Avenue","1",[-83.681448021609981,32.859018269315428]),
  MaconStop.new("480","Ridge Avenue and Belvedere","1",[-83.681992893960086,32.859464537479056]),
  MaconStop.new("481","Ridge Avenue and Albermarle Place","1",[-83.682894462043464,32.86012537863035]),
  MaconStop.new("482","Ridge Avenue and Riverdale Drive","1",[-83.683964154037824,32.86084016050529]),
  MaconStop.new("483","Ridge Avenue and Merritt Avenue","1",[-83.68488632014909,32.861589897832843]),
  MaconStop.new("484","Ridge Avenue and Roycrest Drive","1",[-83.686816144959181,32.86285871859004]),
  MaconStop.new("485","Vineville Avenue and West Ridge Circle","1",[-83.691250404709919,32.864261415519977]),
  MaconStop.new("486","Vineville Avenue near Charter Hospital","1",[-83.694335460120655,32.866049727531504]),
  MaconStop.new("487","Vineville Avenue near Charter Hospital","1",[-83.694250312927622,32.866227068092819]),
  MaconStop.new("488","New Street @ The Medical Center","2",[-83.635363574892054,32.834665116691063]),
  MaconStop.new("489","Pine Street and Spring Street","2",[-83.636762506968196,32.835426603022341]),
  MaconStop.new("490","Cotton Avenue and College Street","2",[-83.640358160274488,32.836197330504504]),
  MaconStop.new("491","Oglethrope Street and Tatnall Street","2",[-83.645627512013547,32.834263027224331]),
  MaconStop.new("492","College Street near RR under pass","2",[-83.643545960041919,32.83476755050188]),
  MaconStop.new("493","Oglethorpre Street and Adams Street","2",[-83.647073749603919,32.835096791002513]),
  MaconStop.new("494","Adams Street","2",[-83.648040946403299,32.83400817038639]),
  MaconStop.new("495","Adams Street","2",[-83.648771856288874,32.833084115261428]),
  MaconStop.new("496","Coleman Avenue and Linden Avenue","2",[-83.649927328260887,32.833337216583779]),
  MaconStop.new("497","Coleman Avenue and Johnson Avenue","2",[-83.650963048483334,32.833954024129142]),
  MaconStop.new("498","Coleman Avenue and I-75","2",[-83.651645344138132,32.834652145165549]),
  MaconStop.new("499","Coleman Avenue and Duncan Avenue","2",[-83.652327841351536,32.835317152789756]),
  MaconStop.new("500","Napier Avenue and Vine Street","2",[-83.654010898700164,32.835903484072318]),
  MaconStop.new("501","Napier Avenue and Vine Street","2",[-83.655206970692205,32.835924932276733]),
  MaconStop.new("502","Napier Avenue and Blackmon Avenue","2",[-83.656285481832498,32.835929334910524]),
  MaconStop.new("503","Naper Avenue and Hendley Street","2",[-83.657775504825992,32.835985067423884]),
  MaconStop.new("504","Napier Avenue and Birch Street","2",[-83.659285328376427,32.83600775196097]),
  MaconStop.new("505","Napier Avenue and Patterson Street","2",[-83.660755839864237,32.836046815100467]),
  MaconStop.new("506","Napier Avenue and Pio Nono Avenue","2",[-83.662324305729072,32.836102810533326]),
  MaconStop.new("507","Napier Avenue and Courtland Street","2",[-83.66395188208044,32.836109358418035]),
  MaconStop.new("508","Napier Avenue and Hillyer Avenue","2",[-83.665539868766572,32.836181946787363]),
  MaconStop.new("509","Napier Avenue and Winton Avenue","2",[-83.667030274163551,32.836171349635215]),
  MaconStop.new("510","Napier Avenue","2",[-83.667736211765359,32.836174165742918]),
  MaconStop.new("511","Napier Avenue and Inverness Street","2",[-83.669006943290341,32.836874537085095]),
  MaconStop.new("512","Napier Avenue and Bartlett Street","2",[-83.670556005140185,32.836897241763175]),
  MaconStop.new("513","Napier Avenue and Bartlett Street","2",[-83.670967989358431,32.83686576450102]),
  MaconStop.new("514","Napier Avenue and Ernest Street","2",[-83.672418912669656,32.836904612217701]),
  MaconStop.new("515","Napier Avenue and Bailey Avenue","2",[-83.674752085179733,32.836980024315295]),
  MaconStop.new("516","Napier Avenue","2",[-83.675964236809705,32.837646985399644]),
  MaconStop.new("517","Napier Avenue and Radio Drive","2",[-83.676688069751606,32.837964366444176]),
  MaconStop.new("518","Napier Avenue","2",[-83.681479866245041,32.840300741882793]),
  MaconStop.new("519","Napier Avenue and Burton Avenue","2",[-83.678998859237112,32.838552818595687]),
  MaconStop.new("520","Napier Avenue","2",[-83.682556907018522,32.840586348256302]),
  MaconStop.new("521","Napier Avenue and Carlisle Avenue","2",[-83.683027736008711,32.840555058991399]),
  MaconStop.new("522","Napier Avenue and Cypress","2",[-83.685614255137551,32.840945794025522]),
  MaconStop.new("523","Napier Avenue and Log Cabin","2",[-83.687119099274639,32.8419117615882]),
  MaconStop.new("524","Napier Avenue and Log Cabin","2",[-83.68725681937859,32.841829514224962]),
  MaconStop.new("525","Log Cabin Road and Scotland Avenue","2",[-83.68991443901281,32.839935835431604]),
  MaconStop.new("526","Log Cabin Road and James Road","2",[-83.691410201828816,32.838931665253455]),
  MaconStop.new("527","Log Cabin Road and Sherbrook","2",[-83.692940226462625,32.838854690878257]),
  MaconStop.new("528","Log Cabin Road and Pike Street","2",[-83.695156336420538,32.838829949843792]),
  MaconStop.new("529","Log Cabin Road and Hollingsworth Road","2",[-83.700997895827712,32.835524249991337]),
  MaconStop.new("530","Log Cabin Road","2",[-83.687729609371644,32.841434003316586]),
  MaconStop.new("531","Log Cabin Road","2",[-83.699444076253855,32.836412433734544]),
  MaconStop.new("532","Hollingsworth Road","2",[-83.700263089176644,32.837292907963715]),
  MaconStop.new("533","Hollingsworth Road and Wolf Creek Drive","2",[-83.699745609966541,32.838747824563619]),
  MaconStop.new("534","Hollingsworth Road","2",[-83.699245816030853,32.840567016471169]),
  MaconStop.new("535","Hollingsworth Road","2",[-83.697963480962301,32.842019065737716]),
  MaconStop.new("536","Hollingsworth Road","2",[-83.69695064002245,32.843097472448299]),
  MaconStop.new("537","Hollingsworth Road and Mumford Road","2",[-83.696259061519143,32.847120730902503]),
  MaconStop.new("538","Mumford Road and Case Street","2",[-83.692198527768326,32.84710540108793]),
  MaconStop.new("539","Mumford Road","2",[-83.689383144087216,32.847062358869522]),
  MaconStop.new("540","Napier Avenue and Mumford Road","2",[-83.688099864102867,32.847057457806805]),
  MaconStop.new("541","Napier Avenue near McKenzie Drive","2",[-83.687916111375259,32.849174772653257]),
  MaconStop.new("542","Napier Avenue and Brookdale Avenue","2",[-83.687838764184789,32.852876965555915]),
  MaconStop.new("543","Napier Avenue and Fairmont Avenue","2",[-83.687787427053337,32.855301979006619]),
  MaconStop.new("545","Forsyth Road near Napier Avenue","2",[-83.69943837595072,32.869088873960166]),
  MaconStop.new("546","Forsyth Road","2",[-83.701463488936398,32.870179679694125]),
  MaconStop.new("547","Forsyth Road near Idle Hour","2",[-83.707176521641685,32.87317571418172]),
  MaconStop.new("548","Forsyth Road near Country Club Road","2",[-83.70601141115273,32.872476203013051]),
  MaconStop.new("549","Forsyth Road near Kroger Shopping Center","2",[-83.709813926113995,32.874462649247384]),
  MaconStop.new("550","Forsyth Road near Kroger Shopping Center","2",[-83.708342065379128,32.873794375716088]),
  MaconStop.new("551","Forsyth Road near Kroger Shopping Center","2",[-83.709603173618746,32.87446187933147]),
  MaconStop.new("552","Forsyth Road and Tucker Road","2",[-83.710807483655898,32.87499981920498]),
  MaconStop.new("553","Forsyth Road and Wesleyan Woods Drive","2",[-83.715779707179976,32.876844829080738]),
  MaconStop.new("554","Forsyth Road and Wesleyan Woods Drive","2",[-83.716048437685302,32.876748789224962]),
  MaconStop.new("555","Forsyth Road near Brittany Drive","2",[-83.722990030691747,32.879473666213372]),
  MaconStop.new("556","Forsyth Road and Zebulon Road","2",[-83.724787508331289,32.880207591083249]),
  MaconStop.new("557","Riverside Drive near SS Administration","5",[-83.682623140948863,32.897388936498402]),
  MaconStop.new("558","Hardeman and Monroe St Lane","1",[-83.641545591528399,32.839983660332891]),
  MaconStop.new("559","Hardeman and Franks Lane","1",[-83.643928067786305,32.840642755086833]),
  MaconStop.new("560","Vineville and Pierce Avenue","1",[-83.662378029776363,32.846135263970915]),
  MaconStop.new("561","Vineville and Florida Street","1",[-83.666116429823319,32.84621742380255]),
  MaconStop.new("562","Madison Street and Stewarts Lane","5",[-83.638951593829091,32.843710788151192]),
  MaconStop.new("563","Madison Street","5",[-83.639488780992451,32.842549112674206]),
  MaconStop.new("564","Jefferson Street and Madison Street","5",[-83.640026350501671,32.841320284677622]),
  MaconStop.new("565","Sheraton Drive near Arkwright Road","13",[-83.688863620737493,32.90633866561204]),
  MaconStop.new("566","Sheraton Drive","13",[-83.690843508911996,32.908248797692849]),
  MaconStop.new("567","Sheraton Drive Near Apartments","5",[-83.695285810904522,32.911197839099145]),
  MaconStop.new("568","Sheraton Drive","13",[-83.698853761350648,32.913942004419042]),
  MaconStop.new("569","","0",[-83.702182278346342,32.916841861311383]),
  MaconStop.new("570","Sheraton Drive Near Apartments","13",[-83.702182278346342,32.916841861311383]),
  MaconStop.new("571","Sheraton Drive at Groomes Transportation","13",[-83.703900218877024,32.918191230084794]),
  MaconStop.new("572","Sheraton Drive and Sheraton Blvd","13",[-83.705222112367167,32.919158597966174]),
  MaconStop.new("573","Sheraton Drive and Gateway Drive","0",[-83.70912083574585,32.924791133221291]),
  MaconStop.new("574","Sheraton Drive and Sheraton Blvd North","13",[-83.707150947083036,32.920799683390193]),
  MaconStop.new("575","Sheraton Drive and Gateway Drive","13",[-83.709094181411388,32.924813419284483]),
  MaconStop.new("576","Sheraton Drive and Riverside Drive","13",[-83.711247112461251,32.924194550405808]),
  MaconStop.new("577","Riverside Drive and Bass Road","13",[-83.717500650807352,32.936662273389871]),
  MaconStop.new("578","Riverside Drive and Hall Road","13",[-83.70566714345037,32.915220781124596]),
  MaconStop.new("579","Riverside Drive near Access Road","13",[-83.699347177647908,32.910944487477487]),
  MaconStop.new("580","Riverside Drive and Sue Drive","13",[-83.693979486258499,32.907342978294309]),
  MaconStop.new("581","Riverside Drive and North Crest Blvd","Route",[-83.690806601972184,32.905226909874123]),
  MaconStop.new("582","Vineville Avenue near Country Club Road","2",[-83.704975832697656,32.871997714942829]),
  MaconStop.new("583","Vineville Avenue near Idle Wild Road","2",[-83.702711439482684,32.870839760474027]),
  MaconStop.new("584","Napier Avenue and Canyon Road","2",[-83.698374400862505,32.865671790495902]),
  MaconStop.new("585","Napier Avenue and Park Street","2",[-83.69207805387984,32.859069922827807]),
  MaconStop.new("586","Napier Avenue near Apartments","2",[-83.689110210377308,32.857483281875318]),
  MaconStop.new("587","Napier Avenue and Atlantic Avenue","Bellvue/ Log Cabin",[-83.687836616990836,32.850410631821134]),
  MaconStop.new("588","Mumford Road and Lawton Road","2",[-83.69380622076558,32.847112322346902]),
  MaconStop.new("589","Hollingsworth Road","2",[-83.696209699566623,32.845673760833513]),
  MaconStop.new("590","Good Will Center","9",[-83.731704984162278,32.803532765709228]),
  MaconStop.new("592","Macon Mall","9",[-83.694350169219589,32.817293670237191]),
  MaconStop.new("593","Anthony Terrace","9",[-83.667757728982039,32.817592782264136]),
  MaconStop.new("594","Pio Nono and Dent Street","9",[-83.662875739107278,32.818668147928136]),
  MaconStop.new("595","Pio Nono and Ell Street","9",[-83.662948337291795,32.816637790556477]),
  MaconStop.new("596","Anthony Rd and Arlington Park","3",[-83.683351088283246,32.822882499238979]),
  MaconStop.new("597","Anthony Road and Henderson Drive","3",[-83.678656844689456,32.825296556198317]),
  MaconStop.new("598","Walmar Street","6",[-83.713699700892221,32.783399924631112]),
  MaconStop.new("599","Bloomfield Road and Thrasher Circle","6",[-83.707808534139403,32.783499849082084]),
  MaconStop.new("600","Bloomfield Road and Leone Dr","6",[-83.707765523525453,32.782548992155235]),
  MaconStop.new("601","Bloomfield Road near Village Green Drive","6",[-83.707771234799139,32.781436491555013]),
  MaconStop.new("602","Rocky Creek Road near Apartments","6",[-83.676520506096693,32.7862131940852]),
  MaconStop.new("603","Pio Nono Avenue near Rice Mill Road","6",[-83.66834370364522,32.792491936406321]),
  MaconStop.new("604","Pio Nono Avenue near Pio Nono Circle","6",[-83.664589202070388,32.800062274664356]),
  MaconStop.new("605","Mason Street and Ell Street","6",[-83.66195703733581,32.816597799236241]),
  MaconStop.new("606","Clinton Road and Pitts Street","4",[-83.617794890046127,32.862352434058586]),
  MaconStop.new("607","Coliseum Drive and Clinton Street","11",[-83.617249480038907,32.84300086794326]),
  MaconStop.new("608","Main Street and Garden Street","11",[-83.615099521495679,32.844172145528489]),
  MaconStop.new("609","Main Street and Fairview Avenue","11",[-83.611102673200079,32.845611542548262]),
  MaconStop.new("610","Woolfolk Street and Fort Hill Street","11",[-83.61265466550951,32.849688187319522]),
  MaconStop.new("611","New Clinton Road and Companion Drive","11",[-83.587180434718704,32.858516217782494]),
  MaconStop.new("612","New Clinton Road and Ollie Drive","11",[-83.586725962232578,32.859745085386699]),
  MaconStop.new("613","Jordan Avenue and Recreation Road","11",[-83.573823185477139,32.852951942140116]),
  MaconStop.new("614","Jordan Avenue","11",[-83.573816669781522,32.853931665447057]),
  MaconStop.new("615","Commodore Drive and Gateway Avenue","11",[-83.573806694755561,32.868854014242402]),
  MaconStop.new("616","Truitt Place and Pasadena Drive","11",[-83.570259147150537,32.869615928647292]),
  MaconStop.new("617","Strattford Drive and Bethune Avenue","11",[-83.57287472768553,32.865759605977928])
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

get '/geotransit' do
  erb :georequest
end

post '/geotransit' do
  if params['address']
    if params["city"] == "macon"
      params['address'] = params['address'] + ", Macon, GA"
    url = 'http://www.mapquestapi.com/geocoding/v1/address?key=Fmjtd%7Cluua2l07nq%2C22%3Do5-hyy0g&location=' + URI.escape(params['address'])
    url = URI.parse(url)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get('/geocoding/v1/address?key=Fmjtd%7Cluua2l07nq%2C22%3Do5-hyy0g&location=' + URI.escape(params['address']))
    }
    response = res.body
    lng = response.slice( response.index('"lng":') + 6 .. response.index('"lat"') - 2 )
    lng = Float(lng)
    lat = response.slice( response.index('"lat":') + 6 .. response.length )
    lat = lat.slice( 0 .. lat.index('}') - 1 )
    lat = Float(lat)
    closest = ''
    if params["city"] == "sf"
      closest = closest_bart(lat, lng)
      closest.getid()
    elsif params["city"] == "macon"
      closest = closest_macon(lat, lng)
      if closest.getroute() == "1" or closest.getroute() == "2" or closest.getroute() == "7"
        # library routes
        terminalx = -83.623976
        terminaly = 32.833738
        libraryx = -83.63824
        libraryy = 32.838782
        stopdist = ( closest.getlng() - terminalx )**2 + ( closest.getlat() - terminaly )**2
        librarydist = ( libraryx - terminalx )**2 + ( libraryy - terminaly )**2
        if librarydist < stopdist
          "Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station"
        else
          "Take a bus from <i>" + closest.getname() + "</i> away from Terminal Station"        
        end
      else
        # go to Terminal Station
        "Take a bus from <i>" + closest.getname() + "</i> toward Terminal Station, then take the next Vineville (1) bus."
      end
    end
  else
    "no address"
  end
end

get '/transit' do
  if params['eventname']
    @tevents = TransitEvent.search(params['eventname'])
    
    eventDest = @tevents.first.gotostation
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
