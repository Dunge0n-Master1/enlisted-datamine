options no_aot
require ecs
require DagorConsole

[console_cmd(name="ai.bot_leader_nav_mode", hint="0 - default, 1 - enable, 2 - disable")]
def bot_leader_nav_debug_mode(val : int)
  var upd = false
  let found = ecs::find_query() <| $ [es] (eid : EntityId;
                                           var bot_leader_nav_debug__mode : int&;
                                           bot_leader_nav_debug__draw : bool)
    if (val <= 0) && !bot_leader_nav_debug__draw
      destroyEntity(eid)
    else
      bot_leader_nav_debug__mode = val
      upd = true
    return true
  if !found && (val > 0)
    createEntity("bot_leader_nav_debug") <| $(var init : ComponentsInitializer)
      set(init, "bot_leader_nav_debug__mode", val)
    upd = true
  if upd
    if val == 1
      ecs::query() <| $ [es] (squad__leader : ecs::EntityId; squad__ownerPlayer : ecs::EntityId)
        ecs::query(squad__ownerPlayer) <| $ [es(REQUIRE=playerIsBot)] ()
          addSubTemplate(squad__leader, "bot_leader_nav")
    elif val == 2
      ecs::query() <| $ [es(REQUIRE=bot_leader_nav)] (eid : EntityId)
        removeSubTemplate(eid, "bot_leader_nav")

[console_cmd(name="ai.bot_leader_nav_draw", hint="0 - disable, 1 - enable")]
def bot_leader_nav_debug_draw(val : int)
  let found = ecs::find_query() <| $ [es] (eid : EntityId;
                                           bot_leader_nav_debug__mode : int;
                                           var bot_leader_nav_debug__draw : bool&)
    if (val <= 0) && (bot_leader_nav_debug__mode <= 0)
      destroyEntity(eid)
    else
      bot_leader_nav_debug__draw = val > 0
    return true
  if !found && (val > 0)
    createEntity("bot_leader_nav_debug") <| $(var init : ComponentsInitializer)
      set(init, "bot_leader_nav_debug__draw", val > 0)
