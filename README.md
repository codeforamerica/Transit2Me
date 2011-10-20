# PDF Archive

PDF Archive is a simple PDF storage and retrieval system. Uploading a PDF will store it, create a preview image for search listings, and extract the text from it so it can be indexed for search.

## Setup

    git clone git://github.com/jonmagic/pdf_archive.git
    cd pdf_archive
    gem install bundle
    bundle

## Run the tests

    bundle exec rake

## Run the app and background worker

    gem install foreman
    foreman start

You can now open the app in your browser http://localhost:3000

## Running on Heroku

Running this on Heroku requires the following steps:

### Step 1: Create the app on the Heroku Cedar stack

    gem install heroku
    heroku apps:create app_name --stack cedar

### Step 2: Add MongoHQ Addon

The MongoHQ Addon will give us a small free MongoDB instance for storing our documents.

    heroku addons:add mongohq:free

### Step 3: Configure For S3

First setup an Amazon AWS account, get your key, secret, and create a bucket. Then take those values and configure the environment variables on Heroku.

    heroku config:add AWS_ACCESS_KEY_ID=<aws_access_key_id> AWS_SECRET_ACCESS_KEY=<aws_secret_access_key> BUCKET_NAME=<bucket_name>

### Step 4: Deploy to Heroku

    git push heroku master

When it is finished deploying it will give you the url to your app. Visit in the browser and enjoy!

## License

Copyright (c) 2011 Jonathan Hoyt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.