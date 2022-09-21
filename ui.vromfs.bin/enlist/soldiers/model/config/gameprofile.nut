from "%enlSqGlob/ui_library.nut" import *

let {configs} = require("%enlist/meta/configs.nut")

let gameProfile = Computed(@() configs.value?.gameProfile ?? {})
let allArmiesInfo = Computed(function() {
  let res = {}
  foreach (c in gameProfile.value?.campaigns ?? {})
    foreach (a in c?.armies ?? {})
      res[a.id] <- a
  return res
})

return {
  gameProfile
  allArmiesInfo
}