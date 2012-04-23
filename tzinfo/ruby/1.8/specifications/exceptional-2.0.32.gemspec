# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "exceptional"
  s.version = "2.0.32"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Contrast"]
  s.date = "2010-12-16"
  s.description = "Exceptional is the Ruby gem for communicating with http://getexceptional.com (hosted error tracking service). Use it to find out about errors that happen in your live app. It captures lots of helpful information to help you fix the errors."
  s.email = "hello@contrast.ie"
  s.executables = ["exceptional"]
  s.files = ["bin/exceptional"]
  s.homepage = "http://getexceptional.com/"
  s.require_paths = ["lib"]
  s.requirements = ["json_pure, json-jruby or json gem required"]
  s.rubyforge_project = "exceptional"
  s.rubygems_version = "1.8.16"
  s.summary = "getexceptional.com is a hosted service for tracking errors in your Ruby/Rails/Rack apps"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
  end
end
