import "%dngscripts/ecs.nut" as ecs

let { battleMusicEnabled } = require("%ui/hud/state/sound_options_state.nut")

let setBattleMusicEnabledQuery = ecs.SqQuery("setBattleMusicEnabledQuery", {
  comps_rw = [["battle_music__enabled", ecs.TYPE_BOOL]]
})

battleMusicEnabled.subscribe(function(enabled) {
  setBattleMusicEnabledQuery(function(_eid, comp) {
    comp.battle_music__enabled = enabled
  })
})
