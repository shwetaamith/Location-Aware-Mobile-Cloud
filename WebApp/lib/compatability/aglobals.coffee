@Collections = {}
@_app = NOOP: -> return
Package['kadira:flow-router'] = Package['ostrio:flow-router-extra'];


if Meteor.isClient
  window.IS_RENDERED = false
  ClientStorage.set('blamed', []) if not ClientStorage.has('blamed') or not _.isArray ClientStorage.get 'blamed'
  ClientStorage.set('unlist', true) if not ClientStorage.has('unlist') or not _.isBoolean ClientStorage.get 'unlist'
  ClientStorage.set('secured', false) if not ClientStorage.has('secured') or not _.isBoolean ClientStorage.get 'secured'
  ClientStorage.set('userOnly', false) if not ClientStorage.has('userOnly') or not _.isBoolean ClientStorage.get 'userOnly'

  _app.subs            = new SubsManager()
  _app.blamed          = new ReactiveVar ClientStorage.get 'blamed'
  _app.unlist          = new ReactiveVar ClientStorage.get 'unlist'
  _app.secured         = new ReactiveVar ClientStorage.get 'secured'
  _app.uploads         = new ReactiveVar false
  _app.userOnly        = new ReactiveVar ClientStorage.get 'userOnly'
  _app.storeTTL        = 86400000
  _app.currentUrl      = -> Meteor.absoluteUrl((FlowRouter.current().path or document.location.pathname).replace(/^\//g, '')).split('?')[0].split('#')[0].replace '!', ''
  _app.storeTTLUser    = 432000000
  _app.showProjectInfo = new ReactiveVar false

  _app.serviceConfiguration = new ReactiveVar {}
  Meteor.call 'getServiceConfiguration', (error, serviceConfiguration) ->
    if error
      console.error error
    else
      _app.serviceConfiguration.set serviceConfiguration
    return
  
  Meteor.autorun ->
    ClientStorage.set 'blamed', _app.blamed.get()
    return

  Meteor.autorun ->
    ClientStorage.set 'unlist', _app.unlist.get()
    return

  Meteor.autorun ->
    ClientStorage.set 'secured', _app.secured.get()
    return

  Meteor.autorun ->
    ClientStorage.set 'userOnly', _app.userOnly.get()
    return

  ClientStorage.set('uploadTransport', 'ddp') unless ClientStorage.has 'uploadTransport'
  Template.registerHelper 'urlCurrent', -> _app.currentUrl()
  Template.registerHelper 'url', (string = null) -> Meteor.absoluteUrl string
  Template.registerHelper 'filesize', (size = 0) -> filesize size
  Template.registerHelper 'extless', (filename = '') ->
    parts = filename.split '.'
    parts.pop() if parts.length > 1
    return parts.join '.'
  Template.registerHelper 'DateToISO', (time) ->
    return 0 unless time
    if _.isString(time) or _.isNumber time
      time = new Date time
    time.toISOString()

  Template._404.onRendered ->
    window.IS_RENDERED = true
    return

  Template._layout.helpers
    showProjectInfo: -> _app.showProjectInfo.get()

  Template._layout.events
    'click [data-show-project-info]': (e, template) ->
      e.preventDefault()
      $('.gh-ribbon').toggle()
      _app.showProjectInfo.set !_app.showProjectInfo.get()
      false

  marked.setOptions
    highlight: (code) ->  hljs.highlightAuto(code).value
    renderer: new marked.Renderer()
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: true
    smartLists: true
    smartypants: false

  Meteor.startup ->
#      @Collections = {}
  #    @_app = NOOP: -> return
    $('html').attr 'itemscope', ''
    $('html').attr 'itemtype', 'http://schema.org/WebPage'
    $('html').attr 'xmlns:og', 'http://ogp.me/ns#'
    $('html').attr 'xml:lang', 'en'
  #  $('html').attr 'lang', 'en'
    if Session.get('lat') == undefined or Session.get('lon') == undefined
      navigator.geolocation.getCurrentPosition (position) ->
        Session.set 'lat', position.coords.latitude
        Session.set 'lon', position.coords.longitude
      return


    console.log("Getting user location")
    navigator.geolocation.getCurrentPosition (position) ->
      userLocationRecord = UserLocation.findOne {key: Meteor.userId()}
      lat = position.coords.latitude
      long = position.coords.longitude
      console.log(userLocationRecord)
      if userLocationRecord
        UserLocation.update {_id: userLocationRecord._id}, $set:{value: [lat, long]}
      else
        UserLocation.insert {key: Meteor.userId(), value: [lat, long]}

