class PdfUploader < CarrierWave::Uploader::Base
  Grim::WIDTH = 100
  storage PdfArchive.environment == "production" ? :fog : :file

  def cache_dir
    "#{PdfArchive.root}/tmp/cache/#{model.id}"
  end

  def store_dir
    if PdfArchive.environment == 'test'
      "#{PdfArchive.root}/tmp/documents/#{model.id}"
    elsif PdfArchive.environment == 'production'
      "documents/#{model.id}"
    else
      "#{PdfArchive.root}/public/documents/#{model.id}"
    end
  end

  def grim
    cache_stored_file! unless cached?
    Grim.reap(cache_path)
  end

  def create_preview
    cache_stored_file! unless cached?
    output_path = File.join(cache_dir, 'preview.jpg')
    grim[0].save(output_path)
    return output_path
  end
end