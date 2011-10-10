require 'spec_helper'

describe ProcessPdf do
  let(:document) { Document.create(:pdf => pdf_fixture('onepage.pdf')) }

  describe ".perform" do
    before(:all) do
      ProcessPdf.perform(document.id)
      document.reload
    end

    it "creates a preview image" do
      File.exists?(File.join(tmp_dir, 'documents', document.id, 'preview.jpg')).should be_true
    end

    it "extracts and saves pdf text to document" do
      document.page_contents.length.should > 0
    end

    it "creates search terms for hunt" do
      document.searches['default'].length.should > 0
    end
  end
end