import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let isDedicated = require_optional("dedicated") != null
if (isDedicated)
  return

let {DBGLEVEL} = require("dagor.system")
let {has_network} = require("net")
let {crossnetworkPlay, CrossplayState} = require("%enlSqGlob/crossnetwork_state.nut")

let platform = require("%dngscripts/platform.nut")
if (!(platform.is_ps5 || (DBGLEVEL > 0 && platform.is_pc)))
  return

local {hasPremium = @() false, reportPremiumFeatureUsage = @(...) log(vargv)} = require_optional("sony.user")
if (!platform.is_sony && DBGLEVEL>0) {
  hasPremium = @() true
  reportPremiumFeatureUsage = @(is_crossplay_enabled, is_spectator)
    log($"reportPremiumFeatureUsage, is_crossplay_enabled:{is_crossplay_enabled}, is_spectator:{is_spectator}")
}

let spectatorQuery = ecs.SqQuery("spectatorQuery", {comps_ro = [["is_local", ecs.TYPE_BOOL], ["specTarget", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID]]})
let isSpectating = @() spectatorQuery.perform(function(_eid, comp) {
  if (!comp.is_local)
    return null
  if (comp.specTarget != ecs.INVALID_ENTITY_ID)
    return true
})

ecs.register_es("report_premium_usage_es", {
    function onUpdate(_dt, _eid, _comp){
      if (!has_network() || !hasPremium())
        return
      reportPremiumFeatureUsage(crossnetworkPlay.value != CrossplayState.OFF, isSpectating())
    }
  },
  {comps_rq=["msg_sink"]},
  { updateInterval=7.0, tags="gameClient", after="*", before="*" }
)

