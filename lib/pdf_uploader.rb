class PdfUploader < CarrierWave::Uploader::Base
  Grim::WIDTH = 100
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

  def grim
    @grim ||= Grim.reap(cache_path)
  end

  def page_count
    @page_count ||= begin
      cache_stored_file! unless cached?
      grim.count
    end
  end

  def create_preview
    cache_stored_file! unless cached?
    grim[0].save(File.join(store_dir, 'preview.jpg'))
  end

  def extract_text(index)
    cache_stored_file! unless cached?
    grim[index].text
  end
end