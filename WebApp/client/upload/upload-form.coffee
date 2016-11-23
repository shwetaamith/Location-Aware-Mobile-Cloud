Template.uploadForm.onCreated ->
  self          = @
  @error        = new ReactiveVar false
  @uploadQTY    = 0
  @showSettings = new ReactiveVar false


  @initiateUpload = (event, files) ->
    if _app.uploads.get()
      return false

    unless files.length
      self.error.set "Please select a file to upload"
      return false

    if files.length > 6
      self.error.set "Please select up to 6 files"
      return

    self.uploadQTY = files.length

    cleanUploaded = (current) ->
      _uploads = _.clone _app.uploads.get()
      if _.isArray _uploads
        _.each _uploads, (upInst, index) ->
          if upInst.file.name is current.file.name
            _uploads.splice index, 1
            if _uploads.length
              _app.uploads.set _uploads
            else
              self.uploadQTY = 0
              _app.uploads.set false
          return
      return

    uploads    = []
    transport  = ClientStorage.get 'uploadTransport'
    created_at = +new Date

    if Meteor.userId()
#      console.log("Hello inside upload")
      secured  = _app.secured.get()
      secured  = false unless _.isBoolean secured
      if secured
        unlisted = true
      else
        unlisted = _app.unlist.get()
        unlisted = true unless _.isBoolean unlisted
      ttl      = new Date(created_at + _app.storeTTLUser)
    else
      unlisted = false
      secured  = false
      ttl      = new Date(created_at + _app.storeTTL)

    _.each files, (file, i) ->
      Collections.files.insert(
        file: file
        meta:
          blamed:     0
          secured:    secured
          expireAt:   ttl
          unlisted:   unlisted
          downloads:  0
          created_at: created_at - 1 - i
        streams: 'dynamic'
        chunkSize: 'dynamic'
        transport: transport
        # allowWebWorkers: false
      ,
        false # Use manual start, so we can attach event listeners
      ).on('end', (error, fileObj) ->
#        console.log(Geolocation.currentLocation())
        console.log(Session.get('lat'))
        console.log(Session.get('lon'))
        obj = this
        obj.lat = Session.get('lat')
        obj.long = Session.get('lon')
        if not error and files.length is 1
          # Redirect to uploaded file
          # Only then we upload one file
#
          # Update Location
          result = UserLocation.findOne {key: Meteor.userId()}
          if result
            UserLocation.update {_id: result._id}, $set:{value: [obj.lat, obj.long]}, (error, result) ->
##               console.log(error)
            #return
          else
            UserLocation.insert {key: Meteor.userId(), value: [obj.lat, obj.long]}, (error, result) ->
#              console.log(error)
            #return

          console.log(FileUserTable.findOne { key: file.name })
          result = FileUserTable.findOne {key: file.name}
          if result
            FileUserTable.update {_id: result._id}, $push:{value: Meteor.userId()}, (error, result) ->
##               console.log(error)
            #return
          else
            FileUserTable.insert {key: file.name, value: [Meteor.userId()]}, (error, result) ->
             console.log(error)
            #return
#            console.log(error)
#          return

          console.log("before writing upload to monitoring table")
          MonitorTable.insert {typeOfAccess: "upload", userId: Meteor.userId(), sizeOfFile: fileObj.size, timeStamp: Math.floor Date.now() / 1000}, (error, result) ->
            console.log(error)
          console.log("upload entry written to monitor table")

          # add MonitoringTable entries to file
          console.log("before writing MonitorTable entries to file")
          entries = MonitorTable.find().fetch()
          console.log(entries)
          pathMonitor = 'C:\\Users\\VISHAL\\Desktop\\ASU Course\\monitor.txt'
          console.log("after initializing fs with npm")
          s = ''
          MonitorTable.find().forEach (monitorLog) ->
            s = s + monitorLog.typeOfAccess + ', ' + monitorLog.userId + ', ' + monitorLog.sizeOfFile + ', ' + monitorLog.timeStamp + '\n'
            return
#          fs = require "fs"
#          fs.writeFile pathMonitor, s, (error) ->
#            console.error("Error writing file", error) if error
          #fsMonitor.writeFile(pathMonitor, s)
          console.log("after writing MonitorTable entries to file")

          #          FileUserTable.findOne { _id: "or2GhgpHmYLyBvhKh" }, (err, result) ->
#            if err
#              console.log("Error")
#              console.log "Unable to find record: #{err}"
#            else
#              console.log("No Error")
#              console.log result # => {  id: "my_favorite_latte", flavor: "honeysuckle" }

#          doc = {filename: file.name, $push: {users: [Meteor.userId()]}}
#          obj = this
#          obj.username = 'Tharun'
#          console.log(obj.username)
#          FileUserTable.find {key:file.name}, (error, result) ->
#            if error
#              console.log("Inside")
#              console.log(error)
#              FileUserTable.insert {key:file.name, users:[Meteor.userId()]}
#            else
#              console.log(result)
#              FileUserTable.update {_id: result._id}, $push:{value: Meteor.userId()}, (error, result) ->
##               console.log(error)
#              return
#          FileUserTable.find {filename:file.name}.nextObject (error, result) ->
#            if error
#              console.log(error)
#            else
#              obj.fileid = result
#              console.log(obj.fileid)
#          return

#          FileUserTable.update {_id:fileid},$push:{value: Meteor.userId()}, {$upsert: true}, (error, result) ->
#            console.log(error)
#          return

#          FileUserTable.insert {name: 'xyz'}, (error, result) ->
#            console.log(error)
#          return

#          console.log("HelloWorld")
#          console.log(file.name)
#          console.log(Meteor.user())
#          console.log(Meteor.userId())
#          console.log(file)
          FlowRouter.go('file', _id: fileObj._id)
        cleanUploaded @
        return
      ).on('abort', ->
        cleanUploaded @
        return
      ).on('error', (error) ->
        console.error error
        self.error.set (if self.error.get() then self.error.get() + '<br />' else '') + @file.name + ': ' + (error?.reason or error)
        Meteor.setTimeout ->
          self.error.set false
        , 10000
        cleanUploaded @
        return
      ).on('start', ->
        uploads.push @
        _app.uploads.set uploads
        return
      ).start()

Template.uploadForm.helpers
  error:   -> Template.instance().error.get()
  uploads: -> _app.uploads.get()
  status:  ->
    i                = 0
    uploads          = _app.uploads.get()
    progress         = 0
    uploadQTY        = Template.instance().uploadQTY
    estimateBitrate  = 0
    estimateDuration = 0
    onPause          = false
    if uploads
      for upload in uploads
        onPause           = upload.onPause.get()
        progress         += upload.progress.get()
        estimateBitrate  += upload.estimateSpeed.get()
        estimateDuration += upload.estimateTime.get()
        i++

      if i < uploadQTY
        progress += 100 * (uploadQTY - i)

      progress         = Math.ceil(progress / uploadQTY)
      estimateBitrate  = filesize(Math.ceil(estimateBitrate / i), {bits: true}) + '/s'
      estimateDuration = do ->
        duration = moment.duration Math.ceil(estimateDuration / i)
        hours    = "#{duration.hours()}"
        hours    = "0" + hours if hours.length <= 1
        minutes  = "#{duration.minutes()}"
        minutes  = "0" + minutes if minutes.length <= 1
        seconds  = "#{duration.seconds()}"
        seconds  = "0" + seconds if seconds.length <= 1
        return "#{hours}:#{minutes}:#{seconds}"
    return {progress, estimateBitrate, estimateDuration, onPause}
  showSettings:    -> Template.instance().showSettings.get()
  showProjectInfo: -> _app.showProjectInfo.get()
  uploadTransport: -> ClientStorage.get 'uploadTransport'


Template.uploadForm.events
  'click input[type="radio"]': (e, template) ->
    ClientStorage.set 'uploadTransport', e.currentTarget.value
    true
  'click [data-pause-all]': (e, template) ->
    e.preventDefault()
    uploads = _app.uploads.get()
    if uploads
      for upload in uploads
        upload.pause()
    false
  'click [data-abort-all]': (e, template) ->
    e.preventDefault()
    uploads = _app.uploads.get()
    if uploads
      for upload in uploads
        upload.abort()
    template.error.set false
    false
  'click [data-continue-all]': (e, template) ->
    e.preventDefault()
    uploads = _app.uploads.get()
    if uploads
      for upload in uploads
        upload.continue()
    false
  'click #fakeUpload': (e, template) ->
    template.$('#userfile').click()
    return
  'dragenter #uploadFile, dragstart #uploadFile': (e, template) ->
    $('#uploadFile').addClass 'file-over'
    return
  'dragleave #uploadFile, dragend #uploadFile': (e, template) ->
    $('#uploadFile').removeClass 'file-over'
    return
  'dragover #uploadFile': (e, template) ->
    e.preventDefault()
    $('#uploadFile').addClass 'file-over'
    e.originalEvent.dataTransfer.dropEffect = 'copy'
    return
  'drop #uploadFile': (e, template) ->
    e.preventDefault()
    template.error.set false
    $('#uploadFile').removeClass 'file-over'
    template.initiateUpload e, e.originalEvent.dataTransfer.files, template
    false
  'change input[name="userfile"]': (e, template) -> template.$('form#uploadFile').submit()
  'submit form#uploadFile': (e, template) ->
    e.preventDefault()
    template.error.set false
    template.initiateUpload e, e.currentTarget.userfile.files
    false
  'click [data-show-settings]': (e, template) ->
    e.preventDefault()
    $('.gh-ribbon').toggle()
    template.showSettings.set !template.showSettings.get()
    false
  'click [data-show-project-info]': (e, template) ->
    e.preventDefault()
    $('.gh-ribbon').toggle()
    _app.showProjectInfo.set !_app.showProjectInfo.get()
    false
