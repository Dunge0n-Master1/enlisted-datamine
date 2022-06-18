module riextra_damage_common shared
require ecs
require RiDestr
require RendInst

def is_bot_or_local(player_eid : EntityId; beh_tree__enabled = false)
  var result = true
  if !beh_tree__enabled
    ecs::query(player_eid) <| $ [es] (is_local : bool)
      result = is_local
  return result

def damage_ri_on_server(handle : riex_handle_t; damage : float; pos : float3; impulse : float3; time : float; eid : ecs::EntityId)
  let riexEid = find_ri_extra_eid(handle)
  setOptional(riexEid, "riOffender", eid)
  apply_damage_to_riextra(handle, damage, pos, impulse, time)
