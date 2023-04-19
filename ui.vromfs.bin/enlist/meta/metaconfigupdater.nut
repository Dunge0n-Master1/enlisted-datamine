from "%enlSqGlob/ui_library.nut" import *
let { update_meta_config } = require("%enlist/meta/clientApi.nut")
let { metaConfig } = require("%enlist/meta/servProfile.nut")

enum ProhibitionStatus {
  Undefined = "Undefined"
  Allowed = "Allowed"
  Prohibited = "Prohibited"
}

let metaGen = Watched(0)

let isLootBoxProhibited = Computed(@() (metaConfig.value?.prohibitingLootbox
  ?? ProhibitionStatus.Prohibited) == ProhibitionStatus.Prohibited)

local function setProhibitingLootbox(state) {
  metaConfig.mutate(@(v) v.__update({ prohibitingLootbox = state }))
  update_meta_config(metaConfig.value, @(_) metaGen(metaGen.value + 1))
}

return {
  isLootBoxProhibited
  ProhibitionStatus
  setProhibitingLootbox
  metaGen
}