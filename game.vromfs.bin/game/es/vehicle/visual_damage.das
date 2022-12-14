require ecs
require vehicle
require dm
require EnlistedDm
require AnimV20
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter

[es(tag=server, on_appear)]
def damage_model_part_alive_update_es_event_handler(evt : Event;
                                                    damage_model : DamageModel;
                                                    var damage_part_alive : BoolList)
  let partsCount = length(damage_model.dmData.parts)
  resize(damage_part_alive, partsCount)
  for i in range(0, partsCount)
    damage_part_alive[i] = false

[es(tag=server, no_order)]
def damage_model_part_alive_update_es(act : ecs::UpdateStageInfoAct;
                                      damage_model : DamageModel;
                                      var damage_part_alive : BoolList)
  let partsCount = length(damage_model.dmData.parts)
  for i in range(0, partsCount)
    damage_part_alive[i] = int(damage_model.dmData.parts[i].relHpFixed) > 0

def show_dmg(show : bool;
             coll_node_id : int;
             collNodeIdToNodeIdMain, collNodeIdToNodeIdDmg : IntList;
             var dmg_animchar : DmgAnimChar&;
             var animchar_render : AnimcharRendComponent&)
  if collNodeIdToNodeIdMain[coll_node_id] >= 0 && collNodeIdToNodeIdDmg[coll_node_id] >= 0
    animchar_render.sceneInstance |> scene_instance_show_node(collNodeIdToNodeIdMain[coll_node_id], !show)
    dmg_animchar.sceneInstance |> scene_instance_show_node(collNodeIdToNodeIdDmg[coll_node_id], show)
    return true;
  return false;

[es(tag=render, on_appear, track=damage_part_alive, before=before_animchar_update_sync, after=visual_damage_remap_init_es)]
def visual_damage_immediate_es(evt : Event;
                               eid : EntityId;
                               visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                               damage_model : DamageModel;
                               damage_part_alive : BoolList;
                               var animchar_render : AnimcharRendComponent&;
                               var dmg_animchar : DmgAnimChar&;
                               var dmg_animchar__renderable : bool&)
  dmg_animchar__renderable = false;
  let damagePartsCount = length(damage_part_alive);
  for i in range(0, damagePartsCount)
    let collNodeId = damage_model.dmData |> get_collision_node_id(i)
    if collNodeId < 0
      continue;
    let showDamage = !damage_part_alive[i];
    show_dmg(showDamage, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
             visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render);
    dmg_animchar__renderable ||= showDamage;
  sendEvent(eid, [[NodesVisibilityWasUpdated]])

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_es_event_handler(evt : EventOnCollisionHit;
                                   eid : EntityId;
                                   visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                                   damage_model : DamageModel;
                                   var animchar_render : AnimcharRendComponent&;
                                   var dmg_animchar : DmgAnimChar&;
                                   var dmg_animchar__renderable : bool&)
  let collNodeId = evt.collNodeId
  let partId = get_part_id_by_coll_node_id(damage_model.dmData, int(collNodeId))
  if partId < 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                            visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
    dmg_animchar__renderable = true;
    sendEvent(eid, [[NodesVisibilityWasUpdated]])

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_part_damaged(evt : EventOnPartDamaged;
                               eid : EntityId;
                               visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                               damage_model : DamageModel;
                               var animchar_render : AnimcharRendComponent&;
                               var dmg_animchar : DmgAnimChar&;
                               var dmg_animchar__renderable : bool&)
  let hpFixed = evt.hpFixed
  let collNodeId = damage_model.dmData |> get_collision_node_id(evt.partId)
  if int(hpFixed) == 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                                   visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
    dmg_animchar__renderable = true;
    sendEvent(eid, [[NodesVisibilityWasUpdated]])

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_on_volumetric_damage(evt : EventOnVolumetricDamage;
                                       eid : EntityId;
                                       visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                                       damage_model : DamageModel;
                                       var animchar_render : AnimcharRendComponent&;
                                       var dmg_animchar : DmgAnimChar&;
                                       var dmg_animchar__renderable : bool&)
  for partIt in evt.damagedParts
    let part = get_ecs_object(partIt)
    let partId = get_int(part, "partId") ?? -1
    let hpFixed = get_int(part, "hpFixed") ?? 0
    let collNodeId = damage_model.dmData |> get_collision_node_id(partId)
    if hpFixed == 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                                 visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
      dmg_animchar__renderable = true;
      sendEvent(eid, [[NodesVisibilityWasUpdated]])
