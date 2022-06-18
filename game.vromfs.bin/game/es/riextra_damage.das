require ecs
require EnlistedNet
require game.events_game
require RiDestr
require RendInst
require game.es.riextra_damage_common

[es(tag=server)]
def riextra_request_damage_server_es(evt : RequestRendinstDamage; eid : ecs::EntityId)
  damage_ri_on_server(evt.handle, evt.damage, evt.pos, evt.impulse, evt.time, eid)

[es(tag=server)]
def riextra_ent_request_damage_server_es(evt : RequestRendinstEntityDamage; eid : ecs::EntityId)
  ecs::query(evt.eid) <| $ [es] (ri_extra : RiExtraComponent)
    damage_ri_on_server(ri_extra.handle, evt.damage, evt.pos, evt.impulse, evt.time, eid)

[es(tag=server, REQUIRE_NOT=override__riextraDamage)]
def riextra_damage_server_es(evt : CmdRendinstDamage; eid : ecs::EntityId; possessedByPlr : ecs::EntityId = INVALID_ENTITY_ID; beh_tree__enabled = false)
  if is_bot_or_local(possessedByPlr, beh_tree__enabled)
    damage_ri_on_server(evt.handle, evt.damage, evt.pos, evt.impulse, evt.time, eid)

// 'netClient' tag because we want true network client here, which sends request to server.
// otherwise we'll have double damage of same rendinst, one by this es, one by riextra_damage_server_es
[es(tag=netClient, REQUIRE_NOT=override__riextraDamage)]
def riextra_damage_client_es(evt : CmdRendinstDamage; eid : ecs::EntityId; possessedByPlr : ecs::EntityId)
  ecs::query(possessedByPlr) <| $ [es] (is_local : bool)
    if is_local
      let riExtraEid = find_ri_extra_eid(evt.handle)
      if riExtraEid != INVALID_ENTITY_ID
        send_net_event(eid, [[RequestRendinstEntityDamage eid=riExtraEid, damage=evt.damage, pos=evt.pos, impulse=evt.impulse, time=evt.time]])
      else
        send_net_event(eid, [[RequestRendinstDamage handle=evt.handle, damage=evt.damage, pos=evt.pos, impulse=evt.impulse, time=evt.time]])

