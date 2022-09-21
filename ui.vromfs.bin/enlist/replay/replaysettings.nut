from "%enlSqGlob/ui_library.nut" import *
let { scan_folder } = require("dagor.fs")
let { flatten } = require("%sqstd/underscore.nut")
let { showReplayTabInProfile } = require("%enlist/featureFlags.nut")
let { load_replay_meta_info, replay_play, get_dir } = require("app")
let { NET_PROTO_VERSION, get_dasevent_net_version } = require("net")
let {get_setting_by_blk_path } = require("settings")
let msgbox = require("%enlist/components/msgbox.nut")
let { remove } = require("system")
let { is_xbox, is_sony} = require("%dngscripts/platform.nut")
let datacache = require("datacache")

let allowProtoMismatch = get_setting_by_blk_path("replay/allowProtoMismatch") ?? false

datacache.init_cache("records",
{
  mountPath = "records"
  maxSize = 0
  timeoutSec = -1
})

let defaultRecordFolder = get_dir("records")
let recordsFolders = [
  defaultRecordFolder,
  "replays/"
]

let currentRecord = Watched(null)
let records = Watched([])
let isReplayTabHidden = Computed(@() !showReplayTabInProfile.value || is_xbox || is_sony)


let isReplayProtocolValid = @(meta)
  meta?.protocol_version == NET_PROTO_VERSION
    && meta?.dasevent_net_version == get_dasevent_net_version()

let function getFiles(){
  return flatten(recordsFolders.map(@(v) scan_folder({
      root = v
      vromfs = false
      realfs = true
      recursive = true
      files_suffix = "*.*" // search for all files because files in datacahe doesn't have ext
    }).map(function(v) {
      let fname = v.split("/").top()
      let recordInfo = load_replay_meta_info(v ?? "")
      let isValid = isReplayProtocolValid(recordInfo)
      let recordTime = recordInfo?.start_timestamp ?? 0
      return { title = fname, id = v, isValid, recordTime }
    })
  ))}


let updateReplays = @() records(getFiles())

let function deleteReplay(replayPath){
  if (records.value.findindex(@(v) v.id == replayPath) != null) {
    remove(replayPath)
    currentRecord(null)
    updateReplays()
  }
}


let function replayPlay(path) {
  let buttons = [{
    text = loc("Ok")
    isCancel = true
  }]
  let replayInfo = load_replay_meta_info(path)
  if (!replayInfo) {
    msgbox.show({
      text = loc("replay/InvalidMeta"),
      buttons
    })
    return
  }

  if (isReplayProtocolValid(replayInfo)) {
    replay_play(path, 0)
    return
  }

  if (allowProtoMismatch)
    buttons.append({
      text = loc("replay/playAnyway")
      action = @() replay_play(path, 0)
      isCurrent = true
    })

  msgbox.show({
    text = loc("replay/protocolMisMatchDoYouWantStart"),
    buttons
  })
}

return {
  currentRecord
  defaultRecordFolder
  isReplayTabHidden
  replayPlay
  deleteReplay
  records
  updateReplays
}