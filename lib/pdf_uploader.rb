class PdfUploader < CarrierWave::Uploader::Base
  storage :file

  def cache_dir
    "#{PdfArchive.root}/tmp/cache/#{model.id}"
  end

  def store_dir
    if PdfArchive.environment == 'test'
      "#{PdfArchive.root}/tmp/documents/#{model.id}"
    else
      "#{PdfArchive.root}/public/documents/#{model.id}"
    end
  end
end