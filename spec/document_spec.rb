require 'spec_helper'

describe Document do
  describe "properties" do
    let(:document) { Document.create(:pdf => pdf_fixture('onepage.pdf')) }

    it "has an id" do
      document.id.should be_present
    end

    it "has a pdf_filename" do
      document.pdf_filename.should == "onepage.pdf"
    end

    it "has an array for page_contents" do
      document.page_contents.should == []
    end
  end
end