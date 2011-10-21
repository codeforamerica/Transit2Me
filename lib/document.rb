class Document
  include MongoMapper::Document
  plugin Hunt

  key :page_contents, Array
  mount_uploader :pdf, PdfUploader
  mount_uploader :preview, PreviewStore
  searches :pdf_filename, :page_contents
end