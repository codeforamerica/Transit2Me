class Document
  include MongoMapper::Document

  key :page_contents, Array
  mount_uploader :pdf, PdfUploader
end