import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let { CmdChatMessage, mkEventSqChatMessage } = require("%enlSqGlob/sqevents.nut")
let console = require("console")
let { TEAM_UNASSIGNED } = require("team")
let {INVALID_USER_ID} = require("matching.errors")
let {find_local_player, find_human_player_by_connid} = require("%dngscripts/common_queries.nut")
let {has_network, INVALID_CONNECTION_ID} = require("net")
let {startswith} = require("string")
let {sendLogToClients} = require("%scripts/game/utils/dedicated_debug_utils.nut")
let {hasDedicatedPermission} = require("%scripts/game/es/dedicated_permission_es.nut")
let {CmdRequestHumanSpeech} = require("speechevents")
let {put_to_mq_raw=null} = require_optional("message_queue")
let {get_arg_value_by_name} = require("dagor.system")
let isDedicated = require_optional("dedicated") != null
let {get_local_unixtime} = require("dagor.time")
let {get_session_id} = require("app")

let filtered_by_team_query = ecs.SqQuery("filtered_by_team_query", {comps_ro=[["team", ecs.TYPE_INT], ["connid",ecs.TYPE_INT]], comps_rq=["player"], comps_no=["playerIsBot"]})
let notfiltered_byteam_query = {comps_ro=[["connid",ecs.TYPE_INT]], comps_rq=["player"], comps_no=["playerIsBot"]}

let chat_log_tube_name = get_arg_value_by_name("chat_log_tube") ?? ""
if (isDedicated)
  print($"chat_log_tube: {chat_log_tube_name}")

let getPlayerPossessedQuery = ecs.SqQuery("getPlayerPossessedQuery", { comps_ro=[["possessed", ecs.TYPE_EID]] })

let function find_connids_to_send(team_filter=null){
  let connids = []
  if (team_filter==null) {
    notfiltered_byteam_query.perform(function(_eid, comp){
      connids.append(comp["connid"])
    }, "ne(connid,{0})")
  }
  else{
    filtered_by_team_query.perform(function(_eid, comp){
      connids.append(comp["connid"])
    },"and(ne(connid,{0}), eq(team,{1}))".subst(INVALID_CONNECTION_ID,team_filter))
  }
  return connids
}

let log_chat_message = (!isDedicated || put_to_mq_raw == null || chat_log_tube_name == "")
  ? @(_data, _mode) null
  : @(data, mode) put_to_mq_raw(chat_log_tube_name, {
      timestamp = get_local_unixtime(),
      session_id = get_session_id(),
      user_id = data.senderUserId,
      nickname = data.name,
      message = data.text,
      team = data.team,
      channel = mode
    })

const SERVERCMD_PREFIX = "/servercmd"
const AUTOREPLACE_HERO = ":hero:"
const AUTOREPLACE_PLAYER = ":player:"

let function sendMessage(evtData){
  let net = has_network()
  let senderEid = net ? find_human_player_by_connid(evtData?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  let senderTeam = ecs.obsolete_dbg_get_comp_val(senderEid, "team", TEAM_UNASSIGNED)
  let senderName = ecs.obsolete_dbg_get_comp_val(senderEid, "name", "")
  let hero = getPlayerPossessedQuery.perform(senderEid, @(_, comp) comp["possessed"]) ?? ecs.INVALID_ENTITY_ID
  let senderBanStatus = ecs.obsolete_dbg_get_comp_val(senderEid, "ban_status", "")
  let mode = evtData?.mode ?? "team"
  let senderUserId = ecs.obsolete_dbg_get_comp_val(senderEid, "userid", INVALID_USER_ID)
  if (startswith(evtData?.text ?? "", SERVERCMD_PREFIX) &&
      hasDedicatedPermission(senderUserId, "send_server_commands")){
    local text = evtData.text.slice(SERVERCMD_PREFIX.len())
    text = text.replace(AUTOREPLACE_HERO, $"{hero}")
    text = text.replace(AUTOREPLACE_PLAYER, $"{senderEid}")
    console.command($"net.set_console_connection_id {evtData?.fromconnid ?? -1}")
    sendLogToClients($"{senderName}: {text}")
    console.command(text)
    log($"console command '{text}' received userid:{senderUserId}")
    return
  }

  let data = { team = senderTeam, name = senderName, sender = senderEid, senderUserId = senderUserId }

  // /servercmd logerr 2
  if (net && senderBanStatus != "" && (mode == "all" || mode == "team")) {
    local text = ""
    if (senderBanStatus == "UNDEFINED")
      text = "chat/is_not_ready_yet"
    else
      text = "chat/not_allowed_to_write"

    data.__update({ text = text, qmsg = { item = "" } })
    let event = mkEventSqChatMessage(data)

    let connectionsToSend = [ecs.obsolete_dbg_get_comp_val(senderEid, "connid", INVALID_CONNECTION_ID)]

    ecs.server_msg_sink(event, connectionsToSend)
    log("Prevent broadcasting chat msg due to", text)
    return
  }

  data.__update({ text = evtData?.text ?? "", qmsg = evtData?.qmsg })
  let event = mkEventSqChatMessage(data)
  let sound = evtData?.sound ?? ""

  let connids = (mode == "team" || mode == "qteam")? find_connids_to_send(senderTeam) : null
  if (sound != "")
    ecs.g_entity_mgr.sendEvent(hero, CmdRequestHumanSpeech(sound))
  ecs.server_msg_sink(event, connids)
  log_chat_message(data, mode)
}

ecs.register_es("chat_server_es", {
    [CmdChatMessage] = @(evt, _eid, _comp) sendMessage(evt.data)
  },
  {comps_rq=["msg_sink"]}
)
