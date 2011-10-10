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

    it "should include form for uploading pdf" do
      last_response.body.should include('Upload')
    end

    it "should include a form for search" do
      last_response.body.should include('Search')
    end
  end
end