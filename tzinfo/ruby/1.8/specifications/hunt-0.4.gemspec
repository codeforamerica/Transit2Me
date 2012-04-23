# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "hunt"
  s.version = "0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = "2011-09-17"
  s.description = "Really basic search for MongoMapper models."
  s.email = ["nunemaker@gmail.com"]
  s.homepage = "http://github.com/jnunemaker/hunt"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.16"
  s.summary = "Really basic search for MongoMapper models."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fast-stemmer>, ["~> 1.0"])
      s.add_runtime_dependency(%q<mongo_mapper>, ["~> 0.9.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3"])
    else
      s.add_dependency(%q<fast-stemmer>, ["~> 1.0"])
      s.add_dependency(%q<mongo_mapper>, ["~> 0.9.0"])
      s.add_dependency(%q<rspec>, ["~> 2.3"])
    end
  else
    s.add_dependency(%q<fast-stemmer>, ["~> 1.0"])
    s.add_dependency(%q<mongo_mapper>, ["~> 0.9.0"])
    s.add_dependency(%q<rspec>, ["~> 2.3"])
  end
end
