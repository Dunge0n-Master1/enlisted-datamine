options no_aot
require ecs
require DagorConsole


[console_cmd(name="ai.turret_avoid_mode", hint="0 - default, 1 - enable, 2 - disable")]
def turret_avoid_debug_mode(val : int)
  var upd = false
  let found = ecs::find_query() <| $ [es] (eid : EntityId; var turret_avoid_debug__mode : int&)
    if val <= 0
      destroyEntity(eid)
    else
      turret_avoid_debug__mode = val
      upd = true
    return true
  if !found && (val > 0)
    createEntity("turret_avoid_debug") <| $(var init : ComponentsInitializer)
      set(init, "turret_avoid_debug__mode", val)
    upd = true
  if upd
    if val == 1
      ecs::query() <| $ [es(REQUIRE_NOT=turret_avoid_nav, REQUIRE=(isTurret, aiAvoidTurret))] (eid : EntityId)
        addSubTemplate(eid, "turret_avoid_nav")
    elif val == 2
      ecs::query() <| $ [es(REQUIRE=turret_avoid_nav)] (eid : EntityId)
        removeSubTemplate(eid, "turret_avoid_nav")
