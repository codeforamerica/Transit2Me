class TransitEvent
  include MongoMapper::Document
  plugin Hunt

  key :eventname, String
  key :eventrunner, String
  key :dateof, String
  key :timeof, String
  key :eventrunnerid, String
  key :gotostation, String
  timestamps!

  searches :eventname, :eventrunner, :gotostation
end