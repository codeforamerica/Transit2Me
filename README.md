# Transit2Me

Transit2Me has two components:

1) Utilities (Beta)

- Scripts to build a transit schedule and animated Google Earth map from GPS tracking data and list of bus stops.

- An interactive map (nextbystop.erb) combining your MapBox map and your transit schedule
<br/>
Visit <a href="https://github.com/codeforamerica/Transit-Map-in-TileMill/">Transit-Map-in-TileMill</a> to see how the map is made in TileMill and uploaded to MapBox!

<img src="http://i.imgur.com/VEzJU.png"/>
<br/>

- An API for programmers to add the next bus arrival from an address or location ( used by Macon-Bibb Transit Authority's texting app )

Sample API calls:
<ul>
<li>/stopnear?address=1000%20Houston%20Ave</li>
<li>/stopbylatlng?lat=32.8&lng=-83.63</li>
</ul>

2) Directions (Alpha)

Organizers list events, and receive a badge which they can embed on their website.

Visitors see a box where they can enter their address and receive transit directions to arrive at your event.

Embedding an Event: <i>/routeit?eventname=My+Event&address=1180%20Washington%20Ave</i>

This component has been designed for two transit systems:
<ul>
<li>BART in San Francisco</li>
<li>Macon-Bibb County Transit buses</li>
</ul>

## Development To-Do:

Roadmap: Timezones, track pledges to take public transit, importing events from Google Calendar, support for GTFS
Data: First run of Route 1, checking of inbound / outbound times on other routes


## Setup

    git clone git://github.com/codeforamerica/Transit2Me.git
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


## About Transit2Me
Transit2Me developed by Code for America under an open source BSD license.

Geocoder.us is used to locate addresses. Free for non-commercial uses.

### About PDF Archive Server

Server based on PDF Archive for Heroku Copyright (c) 2011 Jonathan Hoyt
<small>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.</small>
