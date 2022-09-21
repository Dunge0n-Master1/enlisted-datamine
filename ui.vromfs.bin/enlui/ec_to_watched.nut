from "%enlSqGlob/library_logs.nut" import *

let { frameUpdateCounter } = require("%ui/scene_update.nut")
let { mkLatestByTriggerStream, mkTriggerableLatestWatchedSetAndStorage, MK_COMBINED_STATE } = require("%sqstd/frp.nut")

let mkWatchedSetAndStorage = mkTriggerableLatestWatchedSetAndStorage(frameUpdateCounter)
let mkFrameIncrementObservable = mkLatestByTriggerStream(frameUpdateCounter)

return {
  mkWatchedSetAndStorage
  mkFrameIncrementObservable
  MK_COMBINED_STATE
}