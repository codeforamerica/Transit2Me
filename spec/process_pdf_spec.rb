require 'spec_helper'

describe ProcessPdf do
  let(:document) { Document.create(:pdf => pdf_fixture('onepage.pdf')) }

  describe ".perform" do
    it "calls create_preview on pdf" do
      PdfUploader.any_instance.should_receive(:create_preview)
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