from "%enlSqGlob/ui_library.nut" import *

let { minimapVisibleCurrentCapZonesEids, getZoneWatch } = require("%ui/hud/state/capZones.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { capzoneWidget } = require("%ui/hud/components/capzone.nut")
let smallUnseenBlink = require("%ui/components/unseenSignal.nut")(0.7).__merge({ key = "blink_on" })

let iconSz= [hdpxi(18), hdpxi(16)]

let defIcon = {rendObj = ROBJ_IMAGE image=Picture("!ui/skin#waypoint.svg:{0}:{1}:K".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}
let capzoneSettings = {canHighlight=false, size=[fsh(2),fsh(2)], useBlurBack=false}

let function mkContract(zone, capz) {
  let {attackTeam, alwaysHide=false} = zone
  if (localPlayerTeam.value != attackTeam)
    return null

  return !alwaysHide ? capz : {
    flow     = FLOW_HORIZONTAL
    children = [
      {
        padding = [0 hdpx(15) 0 0]
        children = smallUnseenBlink
      }
      capz
    ]
  }
}

let minimapCapZone = function(eid, transform){
  let zoneWatch = getZoneWatch(eid)
  let watch = [zoneWatch, localPlayerTeam, watchedHeroEid]
  let capz = capzoneWidget(eid, capzoneSettings)

  return function() {
    let {attackTeam, title="", icon = "", isBattleContract=false} = zoneWatch.value
    let heroTeam = localPlayerTeam.value
    let isDefendZone = (attackTeam >= 0 && attackTeam != heroTeam)
    let zoneIcon = (!isDefendZone && title == "" && icon == "") ? defIcon : null

    return {
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      key = eid
      data = {
        zoneEid = eid
        clampToBorder = true
      }
      transform

      children = [
        isBattleContract ? mkContract(zoneWatch.value, capz) : capz
        zoneIcon
      ]
    }
  }
}

let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) minimapCapZone(eid, transform)))
return {
  watch = minimapVisibleCurrentCapZonesEids
  ctor = @(o) memoizedMapByTransform(o?.transform ?? {})(minimapVisibleCurrentCapZonesEids.value).values()
}