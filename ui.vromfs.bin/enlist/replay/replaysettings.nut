from "%enlSqGlob/ui_library.nut" import *
let { scan_folder } = require("dagor.fs")
let { flatten } = require("%sqstd/underscore.nut")
let { showReplayTabInProfile } = require("%enlist/featureFlags.nut")
let { load_replay_meta_info, replay_play } = require("app")
let { NET_PROTO_VERSION, get_dasevent_net_version } = require("net")
let {get_setting_by_blk_path } = require("settings")
let msgbox = require("%enlist/components/msgbox.nut")
let { remove } = require("system")
let datacache = require("datacache")

let allowProtoMismatch = get_setting_by_blk_path("replay/allowProtoMismatch") ?? false
let storageLimitMB = get_setting_by_blk_path("replay/storageLimitMB") ?? 300

datacache.init_cache("records",
{
  mountPath = "records"
  maxSize = storageLimitMB << 20
  manualEviction = true
  timeoutSec = -1
})

let defaultRecordFolder = "replays/"
let recordsFolders = [
  defaultRecordFolder,
]

let currentRecord = Watched(null)
let records = Watched([])
let isReplayTabHidden = Computed(@() !showReplayTabInProfile.value)


let isReplayProtocolValid = @(meta)
  meta?.protocol_version == NET_PROTO_VERSION
    && meta?.dasevent_net_version == get_dasevent_net_version()

let function getFiles() {
  let recordFiles = datacache.get_all_entries("records").map(function(v) {
    let fname = v.path.split("/").top()
    let recordInfo = load_replay_meta_info(v.path ?? "")
    let isValid = isReplayProtocolValid(recordInfo)
    return { title = fname, id = v.path, key = v.key, isValid, recordInfo }
  })

  recordFiles.extend(recordsFolders.map(@(v) scan_folder({
      root = v
      vromfs = false
      realfs = true
      recursive = true
      files_suffix = "*.erpl"
    }).map(function(v) {
      let fname = v.split("/").top()
      let recordInfo = load_replay_meta_info(v ?? "")
      let isValid = isReplayProtocolValid(recordInfo)
      return { title = fname, id = v, isValid, recordInfo }
    })
  ))

  return flatten(recordFiles)
}


let updateReplays = @() records(getFiles())

let function deleteReplay(replayPath){
  let record = records.value.findvalue(@(v) v.id == replayPath)
  if (record == null)
    return
  if (record?.key != null)
    datacache.del_entry("records", record.key)
  else
    remove(replayPath)
  currentRecord(null)
  updateReplays()
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
  isReplayProtocolValid
}