require 'spec_helper'

describe PdfArchive do
  describe ".environment" do
    it "should return the environment" do
      PdfArchive.environment.should == "test"
    end
  end
end

describe 'PDF Archive', :type => :request do
  describe "GET /" do
    before(:each) do
      get '/'
    end

    it "should have app name" do
      last_response.body.should include('PDF Archive')
    end

    it "should include a form for search" do
      last_response.body.should include('Search')
    end

    it "should include form for uploading pdf" do
      last_response.body.should include('Upload')
    end
  end

  describe "POST /" do
    context "with a pdf" do
      before(:each) do
        @count = Document.count
        post '/', params={:pdf => pdf_fixture('onepage.pdf')}
      end

      it "responds ok" do
        last_response.should be_ok
      end

      it "creates a document" do
        Document.count.should > @count
      end
    end

    context "without a pdf" do
      before(:each) do
        @count = Document.count
        post '/', params={:pdf => nil}
      end

      it "responds ok" do
        last_response.should be_ok
      end

      it "does not create a document" do
        Document.count.should == @count
      end
    end
  end

  describe "GET /search" do
    before(:each) do
      document = Document.create(:pdf => pdf_fixture('onepage.pdf'))
      ProcessPdf.perform(document.id)
    end

    context "search by filename" do
      it "shows document in search results" do
        get '/search', params={:q => 'onepage.pdf'}
        last_response.body.should include('onepage.pdf')
      end
    end

    context "search by content" do
      it "shows document in search results" do
        get '/search', params={:q => 'mongomapper'}
        last_response.body.should include('onepage.pdf')
      end
    end

    context "search with no query" do
      it "shows document in search results" do
        get '/search', params={:q => ''}
        last_response.body.should_not include('onepage.pdf')
      end
    end
  end
end