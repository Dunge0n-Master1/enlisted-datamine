let app = require("xbox.app")
let {subscribe} = require("eventbus")


let function register_activation_callback(callback) {
  subscribe(app.activation_event_name, function(result) {
    let senderXuid = result?.sender_xuid
    let invitedXuid = result?.invited_xuid
    let invitationData = result?.data
    callback?(senderXuid, invitedXuid, invitationData)
  })
}


let function register_unconstrain_callback(callback) {
  subscribe(app.unconstrain_event_name, function(_) {
    callback?()
  })
}


let function register_important_live_error_callback(callback) {
  subscribe(app.important_live_error_event_name, function(err) {
    callback?(err)
  })
}


return {
  launch_browser = app.launch_browser
  get_title_id = app.get_title_id

  register_activation_callback
  register_unconstrain_callback
  register_important_live_error_callback
}