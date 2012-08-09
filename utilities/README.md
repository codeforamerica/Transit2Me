# Python scripts

All open source and available under a BSD license.

Written for the <a href="https://github.com/codeforamerica/Transit2Me/tree/master/utilities">Macon-Bibb County Transit Authority</a> by <a href="http://codeforamerica.org">Code for America</a>.

## buswrite.py

### What it does
Reads a CSV file with GPS tracks of your vehicles (can include multiple vehicles and routes).

Outputs a KML file for each vehicle, letting you animate and playback its motion in Google Earth.

We used an export from RouteMatch, but you could use other GPS trackers and vendors.

### Get the source
https://gist.github.com/2907473

## BusTimeTabler.py

### What it does
Reads a CSV file with GPS tracks of your vehicles (can include multiple vehicles and routes).

Also reads a Google Earth / KML file listing bus stops on each route.

Outputs a timetable for each bus stop, using the MaconStop code used to put data online through the Transit2Me API.

We used an export from RouteMatch, but you could use other GPS trackers and vendors.

### Get the source
https://gist.github.com/2980897

## GPSBusTimeTabler.py

### What it does
Reads a CSV file with GPS track of one vehicle.

Also reads a Google Earth / KML file listing bus stops on each route.

Optional: add multiple offset times. For example: record the 10:00AM - 11:00AM trip on a route, then use 60 and 120 minute offsets to predict and include times along next two trips.

Outputs a timetable for each bus stop, using the MaconStop code used to put data online through the Transit2Me API.

We used the Android application "My Tracks", but you could use other GPS trackers and devices.

### Get the source
https://gist.github.com/3179172

## ColumnPopulator.py

### What it does
QGIS script to transform shapefile data

Reads a RouteNames column (Macon Mall, East Macon, Houston) to fill individual columns (Route1, Route2, Route3)

### Get the source
https://gist.github.com/3299769

## MultiColumnPopulator.py

### What it does
QGIS script to transform shapefile data

Reads code from Transit2Me (listing routes available at each stop) to fill individual columns (Route1, Route2, Route3)

### Get the source
https://gist.github.com/3299980