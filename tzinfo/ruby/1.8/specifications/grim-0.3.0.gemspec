# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "grim"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Hoyt"]
  s.date = "2011-10-04"
  s.description = "Grim is a simple gem for extracting a page from a pdf and converting it to an image as well as extract the text from the page as a string. It basically gives you an easy to use api to ghostscript, imagemagick, and pdftotext specific to this use case."
  s.email = ["jonmagic@gmail.com"]
  s.homepage = "http://github.com/jonmagic/grim"
  s.require_paths = ["lib"]
  s.rubyforge_project = "grim"
  s.rubygems_version = "1.8.16"
  s.summary = "Extract slides and text from a PDF."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
