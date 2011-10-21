require 'spec_helper'

describe ProcessPdf do
  let(:document) { Document.create(:pdf => pdf_fixture('onepage.pdf')) }

  describe ".perform" do
    it "calls create_preview on pdf" do
      document.pdf.cache_stored_file!
      output_path = File.join(document.pdf.cache_dir, 'preview.jpg')
      document.pdf.grim[0].save(output_path)
      PdfUploader.any_instance.should_receive(:create_preview).and_return(output_path)
      ProcessPdf.perform(document.id)
    end

    it "extracts text from pages" do
      Grim::Page.any_instance.should_receive(:text)
      ProcessPdf.perform(document.id)
    end

    it "creates search terms for hunt" do
      ProcessPdf.perform(document.id)
      document.reload.searches['default'].length.should > 0
    end
  end
end