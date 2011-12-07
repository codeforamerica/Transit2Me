class PdfUploader < Uploader
  Grim::WIDTH = 100

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
