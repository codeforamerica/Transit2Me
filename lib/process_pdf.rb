class ProcessPdf
  def self.perform(document_id)
    document = Document.find!(document_id)

    page_count = document.pdf.page_count

    if page_count > 0
      document.pdf.create_preview

      0.upto(page_count - 1).each do |index|
        document.page_contents << document.pdf.grim[index].text
      end

      document.save!
    else
      raise 'PDF has no content'
    end
  end
end