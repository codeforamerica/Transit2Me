class ProcessPdf
  def self.perform(document_id)
    document = Document.find!(document_id)
    pdf = document.pdf

    if pdf.grim.count > 0
      document.preview = File.open(pdf.create_preview)

      pdf.grim.each do |page|
        document.page_contents << page.text
      end

      document.save!
    else
      raise 'PDF has no content'
    end
  end
end