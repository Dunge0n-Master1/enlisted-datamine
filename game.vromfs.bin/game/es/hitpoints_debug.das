options no_aot
require ecs
require ecs.common
require game.utils.hero
require game.es.net_console_macro

def set_hp_for_eid(eid : EntityId; value : float)
  query(eid) <| $ [es] (var hitpoints__hp : float&)
    hitpoints__hp = value

[net_console_cmd(name="hitpoints.set_hero_hp")]
def set_hero_hp(value : float; [[net_hero]] eid : EntityId)
  set_hp_for_eid(eid, value)

[net_console_cmd(name="hitpoints.set_hero_maxhp")]
def set_hero_maxhp(value : float; [[net_hero]] eid : EntityId)
  query(eid) <| $ [es] (var set_hero_maxhp : float&)
    set_hero_maxhp = value

[net_console_cmd(name="hitpoints.set_hero_downed")]
def set_hero_downed([[net_hero]] eid : EntityId)
  query(eid) <| $ [es] (var hitpoints__hp : float&; var hitpoints__alwaysAllowRevive : bool&)
    hitpoints__hp = 0f
    hitpoints__alwaysAllowRevive = true

[net_console_cmd(name="hitpoints.set_hero_downed_timed", hint="Down hero with a set timer and no HP drain. Disable death chance on down.")]
def set_hero_downed_long(time : float = 1500.0; [[net_hero]] hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var hitpoints__hp : float&;
                             var hitpoints__downedTimer : float&;
                             var hitpoints__downedKillChanceBase : float&;
                             var hitpoints__downedKillChanceMult : float&;
                             var hitpoints__downedHpPerSecond : float&;
                             var hitpoints__alwaysAllowRevive : bool&)
    hitpoints__downedKillChanceBase = 0.0
    hitpoints__downedKillChanceMult = 0.0
    hitpoints__downedHpPerSecond = 0.0
    hitpoints__downedTimer = time
    hitpoints__hp = 0f
    hitpoints__alwaysAllowRevive = true

[net_console_cmd(name="hitpoints.hero_god_mode")]
def hero_god_mode([[net_hero]] eid : EntityId)
  set_hp_for_eid(eid, 999999f)

[net_console_cmd(name="hitpoints.god_mode_everyone")]
def hero_god_mode_all()
  query() <| $ [es] (var hitpoints__hp : float&)
    hitpoints__hp = 999999f
