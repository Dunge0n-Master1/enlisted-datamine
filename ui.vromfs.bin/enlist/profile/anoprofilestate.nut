from "%enlSqGlob/ui_library.nut" import *

let { requestAnoPlayerStats } = require("%enlSqGlob/userstats/userstat.nut")
let makeBotData = require("botStatsGen.nut")

let isAnoProfileOpened = mkWatched(persist, "isProfileOpened", false)
let anoProfileData = mkWatched(persist, "anoProfileData", false)

let function fetchAnotherProfile(userid){
  requestAnoPlayerStats(userid, function(result) {
    anoProfileData.mutate(@(v) v.__update({ stats = result?.response.stats, isFinal = true }))
    isAnoProfileOpened(true)
  })
}

let function showAnoProfile(profile){
  if (profile.player.userid != -1) {
    anoProfileData(profile)
    fetchAnotherProfile(profile?.player.userid)
  } else {
    anoProfileData(makeBotData(profile))
    isAnoProfileOpened(true)
  }
}

console_register_command(@(userid, name) showAnoProfile({
    player = {
      name
      userid
      nickFrame = "nickFrame_1"
      portrait = "tunisia_axis_t3_1"
      rank = 3
      rating = 1400
    }
  }), "ui.anoProfileTest")

return {
  isAnoProfileOpened
  anoProfileData
  showAnoProfile
}
