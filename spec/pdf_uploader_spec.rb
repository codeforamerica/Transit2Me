require 'spec_helper'

describe PdfUploader do
  let(:document) { Document.create(:pdf => pdf_fixture('onepage.pdf')) }

  describe "#cache_dir" do
    it "returns correct path" do
      document.pdf.cache_dir.should == "#{PdfArchive.root}/tmp/cache/#{document.id}"
    end
  end

  describe "#store_dir" do
    it "returns correct path" do
      document.pdf.store_dir.should == "#{PdfArchive.root}/tmp/documents/#{document.id}"
    end
  end

  describe "#grim" do
    it "returns an instance of Grim::Pdf" do
      document.pdf.grim.class.should == Grim::Pdf
    end
  end

  describe "#create_preview" do
    it "creates a preview image" do
      document.pdf.create_preview
      File.exists?(File.join(tmp_dir, 'documents', document.id, 'preview.jpg')).should be_true
    end
  end
end