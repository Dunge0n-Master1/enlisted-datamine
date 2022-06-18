options no_aot
require ecs
require DagorConsole

[console_cmd(name="ai.squad_sight_avoid_mode", hint="0 - default, 1 - enable for all, 2 - disable for all")]
def squad_sight_avoid_debug_mode(val : int)
  var upd = false
  let found = ecs::find_query() <| $ [es] (eid : EntityId; var squad_sight_avoid_debug__mode : int&)
    if val <= 0
      destroyEntity(eid)
    else
      squad_sight_avoid_debug__mode = val
      upd = true
    return true
  if !found && (val > 0)
    createEntity("squad_sight_avoid_debug") <| $(var init : ComponentsInitializer)
      set(init, "squad_sight_avoid_debug__mode", val)
    upd = true
  if upd
    if val == 1
      ecs::query() <| $ [es(REQUIRE_NOT=squad_sight_avoid, REQUIRE=squad__ownerPlayer)] (eid : EntityId)
        addSubTemplate(eid, "squad_sight_avoid")
    elif val == 2
      ecs::query() <| $ [es(REQUIRE=squad__ownerPlayer)] (eid : EntityId)
        removeSubTemplate(eid, "squad_sight_avoid")
