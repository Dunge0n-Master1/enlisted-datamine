from "%enlSqGlob/ui_library.nut" import *
let {scan_folder} = require("dagor.fs")
let {flatten} = require("%sqstd/underscore.nut")
let { showReplayTabInProfile } = require("%enlist/featureFlags.nut")

let recordsFolders = [
  "records/"
]

let currentRecord = Watched(null)
let isReplayTabHidden = Computed(@() !showReplayTabInProfile.value)

let lrecords = flatten(recordsFolders.map(@(v) scan_folder({
    root = v
    vromfs = false
    realfs = true
    recursive = false
    files_suffix = "*.rpl"
  }).map(function(v) {
    let p = v.split("/")
    let fname = p[p.len()-1]
    return { title = fname, id = v }
  })
))

let records = Computed(@() lrecords)

return {
  records
  currentRecord
  isReplayTabHidden
}