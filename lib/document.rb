class Document
  include MongoMapper::Document
  plugin Hunt

  key :page_contents, Array
  mount_uploader :pdf, PdfUploader
  searches :pdf_filename, :page_contents
end