from "%enlSqGlob/ui_library.nut" import *
let {scan_folder} = require("dagor.fs")
let {flatten} = require("%sqstd/underscore.nut")
let { showReplayTabInProfile } = require("%enlist/featureFlags.nut")

let defaultRecordFolder = "records/"
let recordsFolders = [
  defaultRecordFolder
]

let currentRecord = Watched(null)
let isReplayTabHidden = Computed(@() !showReplayTabInProfile.value)

let function getFiles(){
  return flatten(recordsFolders.map(@(v) scan_folder({
      root = v
      vromfs = false
      realfs = true
      recursive = false
      files_suffix = "*.erpl"
    }).map(function(v) {
      let fname = v.split("/").top()
      return { title = fname, id = v }
    })
  ))}


return {
  getFiles
  currentRecord
  defaultRecordFolder
  isReplayTabHidden
}