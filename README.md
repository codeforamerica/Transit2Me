# Transit2Me

Organizers list events, and receive a badge which they can embed on their website.
Visitors see a box where they can enter their address and receive transit directions to arrive at your event.

Roadmap: Timezones, track pledges to take public transit, importing events from Google Calendar, support for GTFS

The project supports these transit systems:
<ul>
<li>BART in San Francisco</li>
<li>Macon-Bibb County Transit buses</li>
</ul>

API calls:
<ul>
<h3>Retrieving Stops</h3>
<li>/stopnear?address=1000%20Houston%20Ave</li>
<li>/stopbylatlng?lat=32.8&lng=-83.63</li>
<h3>Embedding an Event</h3>
<li>/routeit?eventname=My+Event&address=1180%20Washington%20Ave</li>
</ul>

## Setup

    git clone git://github.com/mapmeld/Transit2Me.git
    cd Transit2Me
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
    heroku apps:create APP_NAME -s cedar

We also need to configure it to run in production

    heroku config:add RACK_ENV=production

### Step 2: Add a MongoDB Addon

The MongoHQ or MongoLab Addons will give us a small free MongoDB instance for storing our documents.

    heroku addons:add mongohq:free

### Step 3: Deploy to Heroku

    git push heroku master
    heroku open

When it is finished deploying it will give you the url to your app. Visit in the browser and enjoy!


## License
Transit2Me Copyright 2012 Code for America, under a BSD license.

Geocoder.us is used to locate addresses. Free for non-commercial uses.

Server based on PDF Archive for Heroku Copyright (c) 2011 Jonathan Hoyt
<small>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.</small>
