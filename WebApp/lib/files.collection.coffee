# DropBox usage:
# Read: https://github.com/VeliovGroup/Meteor-Files/wiki/DropBox-Integration
# env.var example: DROPBOX='{"dropbox":{"key": "xxx", "secret": "xxx", "token": "xxx"}}'
useDropBox = false

# AWS:S3 usage:
# Read: https://github.com/Lepozepo/S3#create-your-amazon-s3
# Read: https://github.com/VeliovGroup/Meteor-Files/wiki/AWS-S3-Integration
# Create and attach CloudFront to S3 bucket: https://console.aws.amazon.com/cloudfront/

# env.var example: S3='{"s3":{"key": "xxx", "secret": "xxx", "bucket": "xxx", "region": "xxx", "cfdomain": "https://xxx.cloudfront.net"}}'
useS3 = false

if Meteor.isServer
  if process.env?.DROPBOX
    Meteor.settings.dropbox = JSON.parse(process.env.DROPBOX)?.dropbox
  else if process.env?.S3
    Meteor.settings.s3 = JSON.parse(process.env.S3)?.s3

  if Meteor.settings.dropbox and Meteor.settings.dropbox.key and Meteor.settings.dropbox.secret and Meteor.settings.dropbox.token
    useDropBox = true
    Dropbox    = Npm.require 'dropbox'
    Request    = Npm.require 'request'
    fs         = Npm.require 'fs'
    bound      = Meteor.bindEnvironment (callback) -> return callback()
    client     = new (Dropbox.Client)({
      key: Meteor.settings.dropbox.key
      secret: Meteor.settings.dropbox.secret
      token: Meteor.settings.dropbox.token
    })
  else if Meteor.settings.s3 and Meteor.settings.s3.key and Meteor.settings.s3.secret and Meteor.settings.s3.bucket and Meteor.settings.s3.region and Meteor.settings.s3.cfdomain
    
    # Fix CloudFront certificate issue
    # Read: https://github.com/chilts/awssum/issues/164
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0

    useS3   = true
    knox    = Npm.require 'knox'
    Request = Npm.require 'request'
    bound   = Meteor.bindEnvironment (callback) -> return callback()
    client  = knox.createClient
      key: Meteor.settings.s3.key
      secret: Meteor.settings.s3.secret
      bucket: Meteor.settings.s3.bucket
      region: Meteor.settings.s3.region

    # Normalize cfdomain
    Meteor.settings.s3.cfdomain = Meteor.settings.s3.cfdomain.replace /\/+$/, ''

@FileUserTable = new (Mongo.Collection)('FileUserTable')
console.log("Created table")
FileUserTable.allow 'insert': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true

FileUserTable.allow 'update': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true


@UserLocation = new (Mongo.Collection)('UserLocation')

UserLocation.allow 'insert': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true

UserLocation.allow 'update': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true

@MonitorTable = new (Mongo.Collection)('MonitorTable')

MonitorTable.allow 'insert': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true

MonitorTable.allow 'update': (userId, doc) ->
  ### user and doc checks ,
  return true to allow insert
  ###
  true

deg2rad = (deg) ->
  deg * Math.PI / 180

topFive = [];
Collections.files = new FilesCollection
  # debug:            true
  # throttle:         false
  # chunkSize:        1024*1024
  storagePath:      'assets/app/uploads/uploadedFiles'
  collectionName:   'uploadedFiles'
  allowClientCode:  true
  protected: (fileObj) ->
    if not fileObj.meta?.secured
      return true
    else if fileObj.meta?.secured and @userId is fileObj.userId
      return true
    return false
  onBeforeRemove: (cursor) ->
    self = @
    res  = cursor.map (file) ->
      return file?.userId is self.userId
    return !~res.indexOf false
  onBeforeUpload: ->
    return if @file.size <= 1024 * 1024 * 128 then true else "Max. file size is 128MB you've tried to upload #{filesize(@file.size)}"
  downloadCallback: (fileObj) ->
    console.log("download clicked")
    clientLoc = UserLocation.findOne(key: this.userId)
    console.log("client location:")
    console.log(clientLoc.value)
    usersWithFile = FileUserTable.findOne {key: fileObj.name}
    dict = {};

    for user in usersWithFile.value
      location = UserLocation.findOne(key: user)
      console.log(location.value)
      # calculate distance
      R = 6371 # Radius of the earth in km
      dLat = deg2rad(location.value[0] - clientLoc.value[0]) # deg2rad below
      dLon = deg2rad(location.value[1] - clientLoc.value[1])
      a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(deg2rad(clientLoc.value[0])) * Math.cos(deg2rad(location.value[0])) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      d = R * c
      console.log("distance: ")
      console.log(d)
      dict[user] = d
      console.log(dict)

    # find 5 minimum distance
    # Create items array
    items = Object.keys(dict).map((key) ->
      [
        key
        dict[key]
      ]
    )
    # Sort the array based on the second element
    items.sort (first, second) ->
      first[1] - (second[1])
    # Create a new array with only the first 5 items
    console.log("distances sorted")
    topFive =  items.slice(0, 5)


#    Meteor.subscribe 'mylocation',
#      onReady: -> console.log 'subscription a success'
#      onError: (err) -> console.log 'subscription a failure', err
    console.log("before the download query")
    if @params?.query.download is 'true'
#      FileUserTable.update {_id: fileObj._id}, $push:{value: this.userId}
      result1 = FileUserTable.findOne {key: fileObj.name}
      console.log(fileObj.name)
      console.log(result1)
      if result1
        FileUserTable.update {_id: result1._id}, $push:{value: this.userId}
        console.log(FileUserTable.findOne {key: fileObj.name})
      Collections.files.collection.update fileObj._id, $inc: 'meta.downloads': 1

      # add entry to monitoring table
      console.log("before writing download to monitoring table")
      MonitorTable.insert {typeOfAccess: "download", userId: this.userId, sizeOfFile: fileObj.size, timeStamp: Math.floor Date.now() / 1000}, (error, result) ->
        console.log(error)
      console.log("download entry written to monitor table")

      # add MonitoringTable entries to file
      console.log("before writing MonitorTable entries to file")
      entries = MonitorTable.find().fetch()
      console.log(entries)
      pathMonitor = 'C:\\Users\\VISHAL\\Desktop\\ASU Course\\monitor.txt'
      fsMonitor = Npm.require('fs')
      console.log("after initializing fs with npm")
      s = ''
      MonitorTable.find().forEach (monitorLog) ->
        s = s + monitorLog.typeOfAccess + ', ' + monitorLog.userId + ', ' + monitorLog.sizeOfFile + ', ' + monitorLog.timeStamp + '\n'
        return
      fsMonitor.writeFile(pathMonitor, s)
      console.log("after writing MonitorTable entries to file")

    return true
  interceptDownload: (http, fileRef, version) ->
    console.log("inside interceptDownload")
    if useDropBox or useS3
      path = fileRef?.versions?[version]?.meta?.pipeFrom
      if path
        # If file is successfully moved to Storage
        # We will pipe request to Storage
        # So, original link will stay always secure

        # To force ?play and ?download parameters
        # and to keep original file name, content-type,
        # content-disposition and cache-control
        # we're using low-level .serve() method
        @serve http,
          fileRef,
          fileRef.versions[version],
          version,
          Request
            url: path
            headers: _.pick http.request.headers, 'range', 'accept-language', 'accept', 'cache-control', 'pragma', 'connection', 'upgrade-insecure-requests', 'user-agent'
        return true
      else
        # While file is not yet uploaded to Storage
        # We will serve file from FS
        return false
    else
      console.log("intercept download... get from user")
      if topFive.length == 1
        return false # allow downlaod from server
      else
        console.log("mobile servers are found")
#        #/ write to file
        path = 'C:\\Users\\VISHAL\\Desktop\\ASU Course\\testFile.txt'
        fs = Npm.require('fs')
        console.log("starting to write locations")
        fs.writeFile(path, topFive)
        console.log("locations are written to file")
        return true  #  don't allow download from server

if Meteor.isServer
  Collections.files.denyClient()
  Collections.files.collection.attachSchema Collections.files.schema

  Collections.files.on 'afterUpload', (fileRef) ->
    self = @
    if useDropBox
      makeUrl = (stat, fileRef, version, triesUrl = 0) ->
        client.makeUrl stat.path, {long: true, downloadHack: true}, (error, xml) -> bound ->
          # Store downloadable link in file's meta object
          if error
            if triesUrl < 10
              Meteor.setTimeout ->
                makeUrl stat, fileRef, version, ++triesUrl
                return
              , 2048
            else
              console.error error, {triesUrl}
          else if xml
            upd = $set: {}
            upd['$set']["versions.#{version}.meta.pipeFrom"] = xml.url
            upd['$set']["versions.#{version}.meta.pipePath"] = stat.path
            self.collection.update {_id: fileRef._id}, upd, (error) ->
              if error
                console.error error
              else
                # Unlink original files from FS
                # after successful upload to DropBox
                self.unlink self.collection.findOne(fileRef._id), version
              return
          else
            if triesUrl < 10
              Meteor.setTimeout ->
                makeUrl stat, fileRef, version, ++triesUrl
                return
              , 2048
            else
              console.error "client.makeUrl doesn't returns xml", {triesUrl}
          return
        return

      writeToDB = (fileRef, version, data, triesSend = 0) ->
        # DropBox already uses random URLs
        # No need to use random file names
        client.writeFile "#{fileRef._id}-#{version}.#{fileRef.extension}", data, (error, stat) -> bound ->
          if error
            if triesSend < 10
              Meteor.setTimeout ->
                writeToDB fileRef, version, data, ++triesSend
                return
              , 2048
            else
              console.error error, {triesSend}
          else
            # Generate downloadable link
            makeUrl stat, fileRef, version
          return
        return

      readFile = (fileRef, vRef, version, triesRead = 0) ->
        fs.readFile vRef.path, (error, data) -> bound ->
          if error
            if triesRead < 10
              readFile fileRef, vRef, version, ++triesRead
            else
              console.error error
          else
            # Write file to DropBox
            writeToDB fileRef, version, data
          return
        return

      sendToStorage = (fileRef) ->
        _.each fileRef.versions, (vRef, version) ->
          readFile fileRef, vRef, version
          return
        return

    else if useS3
      sendToStorage = (fileRef) ->
        _.each fileRef.versions, (vRef, version) ->
          # We use Random.id() instead of real file's _id 
          # to secure files from reverse engineering
          # As after viewing this code it will be easy
          # to get access to unlisted and protected files
          filePath = "files/#{Random.id()}-#{version}.#{fileRef.extension}"
          client.putFile vRef.path, filePath, (error, res) -> bound ->
            if error
              console.error error
            else
              upd = $set: {}
              upd['$set']["versions.#{version}.meta.pipeFrom"] = Meteor.settings.s3.cfdomain + '/' + filePath
              upd['$set']["versions.#{version}.meta.pipePath"] = filePath
              self.collection.update {_id: fileRef._id}, upd, (error) ->
                if error
                  console.error error
                else
                  # Unlink original files from FS
                  # after successful upload to AWS:S3
                  self.unlink self.collection.findOne(fileRef._id), version
                return
            return
          return
        return

    if !!~['png', 'jpg', 'jpeg'].indexOf (fileRef.extension or '').toLowerCase()
      _app.createThumbnails self, fileRef, (fileRef) ->
        if useDropBox or useS3
          sendToStorage self.collection.findOne fileRef._id
        return
    else
      if useDropBox or useS3
        sendToStorage fileRef
    return

  # This line now commented due to Heroku usage
  # Collections.files.collection._ensureIndex {'meta.expireAt': 1}, {expireAfterSeconds: 0, background: true}

  # Intercept FileCollection's remove method
  # to remove file from DropBox or AWS S3
  if useDropBox or useS3
    _origRemove = Collections.files.remove
    Collections.files.remove = (search) ->
      cursor = @collection.find search
      cursor.forEach (fileRef) ->
        _.each fileRef.versions, (vRef, version) ->
          if vRef?.meta?.pipePath
            if useDropBox
              # DropBox usage:
              client.remove vRef.meta.pipePath, (error) -> bound ->
                if error
                  console.error error
                return
            else
              # AWS:S3 usage:
              client.deleteFile vRef.meta.pipePath, (error) -> bound ->
                if error
                  console.error error
                return
          return
        return
      # Call original method
      _origRemove.call @, search
      return

  # Remove all files on server load/reload, useful while testing/development
  # Meteor.startup -> Collections.files.remove {}

  # Remove files along with MongoDB records two minutes before expiration date
  # If we have 'expireAfterSeconds' index on 'meta.expireAt' field,
  # it won't remove files themselves.
  Meteor.setInterval ->
    Collections.files.remove {'meta.expireAt': $lte: new Date((+new Date) + 120000)}, _app.NOOP
    return
  ,
    120000

  Meteor.publish 'latest', (take = 10, userOnly = false)->
    check take, Number
    check userOnly, Boolean
    if userOnly and @userId
      selector = userId: @userId
    else
      selector = {
        $or: [{
          'meta.unlisted': false
          'meta.secured': false
          'meta.blamed': $lt: 3
        },{
          userId: @userId
        }]
      }
    return Collections.files.find(selector, {
      limit: take
      sort: 'meta.created_at': -1
      fields:
        _id: 1
        name: 1
        size: 1
        meta: 1
        type: 1
        isPDF: 1
        isText: 1
        isJSON: 1
        isVideo: 1
        isAudio: 1
        isImage: 1
        userId: 1
        'versions.thumbnail40.type': 1
        extension: 1
        _collectionName: 1
        _downloadRoute: 1
    }).cursor

  Meteor.publish 'file', (_id)->
    check _id, String
    return Collections.files.find({
        $or: [{
          _id: _id
          'meta.secured': false
        },{
          _id: _id
          'meta.secured': true
          userId: @userId
        }]
      }, {
        fields:
          _id: 1
          name: 1
          size: 1
          type: 1
          meta: 1
          isPDF: 1
          isText: 1
          isJSON: 1
          isVideo: 1
          isAudio: 1
          isImage: 1
          extension: 1
          _collectionName: 1
          _downloadRoute: 1
      }).cursor

  Meteor.methods
    filesLenght: (userOnly = false) ->
      check userOnly, Boolean
      if userOnly and @userId
        selector = userId: @userId
      else
        selector = {
          $or: [{
            'meta.unlisted': false
            'meta.secured': false
            'meta.blamed': $lt: 3
          },{
            userId: @userId
          }]
        }
      return Collections.files.find(selector).count()

    unblame: (_id) ->
      check _id, String
      Collections.files.update {_id}, {$inc: 'meta.blamed': -1}, _app.NOOP
      return true

    blame: (_id) ->
      check _id, String
      Collections.files.update {_id}, {$inc: 'meta.blamed': 1}, _app.NOOP
      return true

    changeAccess: (_id) ->
      check _id, String
      if Meteor.userId()
        file = Collections.files.findOne {_id, userId: Meteor.userId()}
        if file
          Collections.files.update _id, {$set: 'meta.unlisted': if file.meta.unlisted then false else true}, _app.NOOP
          return true
      throw new Meteor.Error 401, 'Access denied!'

    changePrivacy: (_id) ->
      check _id, String
      if Meteor.userId()
        file = Collections.files.findOne {_id, userId: Meteor.userId()}
        if file
          Collections.files.update _id, {$set: 'meta.unlisted': true, 'meta.secured': if file.meta.secured then false else true}, _app.NOOP
          return true
      throw new Meteor.Error 401, 'Access denied!'