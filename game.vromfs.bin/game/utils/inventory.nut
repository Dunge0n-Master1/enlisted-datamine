let isDedicated = require_optional("dedicated") != null
let {mq_gen_transactid=null, put_to_mq_raw=null} = require_optional("message_queue")
let {get_arg_value_by_name} = require("dagor.system")
let {logerr} = require("dagor.debug")

let tubeName = get_arg_value_by_name("inventory_tube") ?? ""
if (isDedicated)
  print($"inventory_tube: {tubeName}")


let function isEnabled() {
  return (put_to_mq_raw != null && isDedicated && tubeName != "")
}


let function sendJob(action, appid, userid, data) {
  if (!isEnabled()) {
    logerr($"Refusing to send job {action} to inventory, tube not configured")
    return
  }

  let transactid = mq_gen_transactid()
  put_to_mq_raw(tubeName, {
    action,
    headers = {
      userid,
      appid,
      transactid
    },
    body = data
  })
}

return {
  isEnabled
  sendJob
}
