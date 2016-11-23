Template.login.onRendered ->
  window.IS_RENDERED = true
#  console.log("inside login onrendered")
  return

Template.login.helpers
  unlist:               -> _app.unlist.get()
  secured:              -> _app.secured.get()
  serviceConfiguration: -> _app.serviceConfiguration.get()
#  console.log("Inside helpers")

Template.login.events
  'click [data-login-meteor]': (e) ->
    e.preventDefault()
    Meteor.loginWithMeteorDeveloperAccount()
    return
  'click [data-login-github]': (e) ->
    e.preventDefault()
    Meteor.loginWithGithub()
    return
  'click [data-login-twitter]': (e) ->
    e.preventDefault()
    Meteor.loginWithTwitter {} # Won't work without argument
    return
  'click [data-login-facebook]': (e) ->
    e.preventDefault()
    Meteor.loginWithFacebook {} # Whoot?! Docs?
    return
  'click [data-change-unlist]': (e) ->
    e.preventDefault()
    _app.unlist.set !_app.unlist.get()
    console.log("UNlisted")

    false
  'click [data-change-secured]': (e) ->
    e.preventDefault()
    _app.secured.set !_app.secured.get()
    console.log("Secured")
    false