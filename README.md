# Location Aware Mobile Cloud

This repository contains source code for following applications:
Note: For detailed list of functionalities and purpose of files please check the readme files under respective applications

*  **WebApp**: Cloud server app which stores uploaded files, maintains/queries mobile servers location and stores files they have,
and applies decision algorithm to find the closest neighboring mobile servers for the requested file.
This application is written in JavaScript Framework called MeteorJS. Currently functionalities like
file upload/download and user login are supported. 

* **Android AutoWifiDirectApp**: Mobile Wifi direct peer-to-peer application
* **Android LAWMCloud**: Mobile Client/Server application.


### Screenshots
Screenshots of cloud web app and android app are shared in Screenshots folder



Cloud Server app (http://lawm.cloudapp.net/)
================

__Functionality:__
 - Upload / Download Files
 - Images, PDFs, Texts preview
 - Drag'n'drop support (*files only, folders is not supported yet*)
 - Image processing (*thumbnails, preview*)
 - Login via username-password and social networks (*allows to make uploaded files unlisted and/or private*)
 - Maintains MongoDB tables for user login information, files metadata, mobile servers having the file and monitoring table
 for uploads/downloads.
 - Decision algorithm to find the appropriate neighboring mobile server to serve the client.

__Steps to run the app locally:__
 - Clone the repo: git clone git@gitlab.thothlab.org:tgomudur/Location-Aware-Mobile-Cloud.git
 - Install Meteor(JavaScript Framework): https://www.meteor.com/install
 - Go to WebApp directory in the cloned repo
 - Give the command: meteor
 - Cloud Server app is started on localhost at port 3000: http://localhost:3000/

__Purpose of files:__

|Filename |                           Purpose  |            New/ Modified   |  Comments|
|---|---|---|---|
|upload-form.coffee/, upload-form.jade     |          Uploads files and modifies tables    |       Modified    |  file upload and modify UserLocation, FileUserTable and MonitorTable   tables|
|files.collection.coffee    |         MongoDB collections   |  Modified    |  define collections and intercept download, Decision algorithm.|
|routes.coffee/, router.coffee   |                  url routing     |        New    |       performs url routing using FlowRouter|
|login.coffee/, login.jade   |                   login functionality   |  Modified   |   performs login with validation|
|logout.coffee/,logout.jade   |                  logout functionality |   Modified     | logs out current user|
|file.coffee/ , file.jade       |                renders file |        Modified  |    file rendering and shows metadata|
|packages.json    |                   list of meteor   packages  |      New        |   meteor packages used|
|image-processing.coffee |            creates thumbnails  |    Modified  |    creates thumbnails of uploaded files|
|service-configurations.coffee       |       configurations for multiple platform login |    Modified    |  provide configurations for login via GitHub, Meteor, etc|
|aglobals.coffee  |                   load globals  on meteor startup  |        Modified  |    load all global configurations and configurations on variables when meteor starts and app is started |
|DeviceDetailFragment.java    |       Displaying device details  |  Modified     | Fragment to display details such as the device name and address along with option to connect to it
|DeviceListFragment.java	  |          Lists available servers	    |    Modified    |  Fragment to display as a list the available devices which could be connected to if required|
|FileTransferService.java     |       Transfer files      |    Modified    |  Performs file transfer using Android’s Wifi  peer-to-peer(P2P)|
|WifiDirectActivity.java  |           Main Activity of  Wifi peer-to-peer  application  |      Modified  |    Provides application view and performs connect and disconnect functions|
|WifiDirectBroadcastReceiver.java  |  Broadcast Receiver     | Modified    |   Used to receive intents broadcast by the Android system|
|LAWMCloud/LocationAwareCloude/src/MainActivity.java | Home Page of the App | New | Redirects user to upload/download code| |LAWMCloud/LocationAwareCloude/src/MonitorActivity.java | Display stats | Modified | Helps user see his upload and download stats|
|LAWMCloud/LocationAwareCloude/src/WebAppActivity.java | Display webapp | New | Loads WeApp in a webview container
