from "%enlSqGlob/ui_library.nut" import *

require("connectingToServerMsg.nut")
require("%enlSqGlob/notifications/disconnectedControllerMsg.nut")
require("soldiers/newItemsWnd.nut")

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let {forceRefreshUnlocks, refreshUserstats} = require("%enlSqGlob/userstats/userstat.nut")
let platform = require("%dngscripts/platform.nut")

let canSave = require("%enlist/meta/saveProfile.nut").canSave

isInBattleState.subscribe(function(isActive) {
  if (!isActive)
    gui_scene.setTimeout(1.0, function() {
      refreshUserstats()
      forceRefreshUnlocks()
    })
})

if (platform.is_xbox)
  require("xbox/rateGame.nut")

isInBattleState.subscribe(@(isActive) canSave(!isActive))