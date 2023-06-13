require ecs
require soundEvent
require game.events_game
require RendInst


[es(tag=sound, REQUIRE=humanSound)]
def rendinst_projectile_damage_sound(evt : CmdRendinstDamage)
  let riExtraEid = find_ri_extra_eid(evt.handle)
  ecs::query(riExtraEid) <| $ [es] (rendinst_damage_sound__projectile : string)
    oneshot("[dmg={evt.damage}]{rendinst_damage_sound__projectile}", evt.pos)
