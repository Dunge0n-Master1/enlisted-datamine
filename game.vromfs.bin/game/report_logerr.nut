import "%dngscripts/ecs.nut" as ecs
let {get_setting_by_blk_path} = require("settings")
let {INVALID_CONNECTION_ID} = require("net")
let {INVALID_USER_ID} = require("matching.errors")
let isDedicated = require_optional("dedicated") != null
let dagorDebug = require("dagor.debug")
let {register_logerr_monitor, debug, clear_logerr_interceptors} = dagorDebug
let {DBGLEVEL} = require("dagor.system")
let { sendLogToClients } = require("%scripts/game/utils/dedicated_debug_utils.nut")
let {isInternalCircuit} = require("%dngscripts/appInfo.nut")
let { CmdEnableDedicatedLogger, mkCmdEnableDedicatedLogger } = require("%enlSqGlob/sqevents.nut")

if (!isDedicated){
  ecs.register_es("enableLoggerrMsg",
    {
      [["onInit","onChange"]] = function(eid,comp) {
        if (!comp.is_local || comp.connid==INVALID_CONNECTION_ID)
          return
        let enable = (DBGLEVEL > 0 || isInternalCircuit.value) ? true : get_setting_by_blk_path("debug/receiveServerLogerr")
        debug($"ask for dedicated logerr: {enable}")
        ecs.client_send_event(eid, mkCmdEnableDedicatedLogger({on = enable ?? (DBGLEVEL > 0)}))
      }
    },
    {
      comps_rq=["player"],
      comps_track = [["connid",ecs.TYPE_INT], ["is_local", ecs.TYPE_BOOL]],
    },
    {tags="gameClient"}
  )
  return
}
clear_logerr_interceptors()

let function sendErrorToClient(_tag, logstring, _timestamp) {
  debug($"sending {logstring} to")
  sendLogToClients(logstring)
}

register_logerr_monitor([""], sendErrorToClient)
ecs.register_es("enable_send_logerr_msg_es", {
    [CmdEnableDedicatedLogger] = function(evt, _eid, comp) {
      let on = evt.data?.on ?? false
      debug("setting logerr sending to '{3}', for connid:{0}, userid:{1}, username:'{2}'".subst(comp["connid"], comp["userid"], comp["name"], on))
      comp["receive_logerr"] = on
    }
  },
  {
    comps_ro = [
      ["name", ecs.TYPE_STRING, ""],
      ["connid", ecs.TYPE_INT],
      ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
    ]
    comps_rq = ["player"]
    comps_rw = [["receive_logerr", ecs.TYPE_BOOL]]
  },
  {tags = "server"}
)
