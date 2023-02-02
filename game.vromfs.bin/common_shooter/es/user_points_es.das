require ecs
require game.es.events
require game.events_game
require game.utils.team
require strings


def destroy_point(eid : ecs::EntityId; target : ecs::EntityId)
  destroyEntity(eid)
  let countPtr = get_int(target, "countUserMark")
  if countPtr == null
    return
  let count = deref(countPtr)
  if count < 1
    removeSubTemplate(target, "user_point_entities_tracker")
  else
    set(target, "countUserMark", count - 1)

[es(tag = server, no_order)]
def map_user_point_timer_es(info : UpdateStageInfoAct;
                            eid : ecs::EntityId;
                            timer__destroy : float;
                            target : ecs::EntityId = INVALID_ENTITY_ID)
  if info.curTime > timer__destroy
    destroy_point(eid, target)


[es(tag = server, on_event=CmdDeleteMapUserPoint)]
def destroy_map_user_point_es(evt : Event;
                              eid : ecs::EntityId;
                              target : EntityId = INVALID_ENTITY_ID)
  destroy_point(eid, target)

[es(tag=server, on_disappear, REQUIRE=buildByPlayer)]
def remove_building_marker_es(evt : Event; eid aka building_eid : EntityId)
  find_query() <| $ [es(REQUIRE=userPointBuilding)] (eid : EntityId; userPointTarget : EntityId)
    if userPointTarget == building_eid
      destroyEntity(eid)
      return true
    return false

[es(tag = server)]
def clear_all_map_user_point_es(evt : CmdClearAllAttachedUserPoint;
                                eid : ecs::EntityId;
                                target : ecs::EntityId;
                                team : int)
  if is_teams_friendly(team, evt.team)
    if target == evt.target
      destroy_point(eid, target)

[es(tag=server)]
def clear_attached_points_es(evt : EventOnLootPickup; team : int)
  let itemEid = evt.itemEid
  if itemEid |> has("userPointTracker")
    broadcastEvent([[CmdClearAllAttachedUserPoint target=itemEid, team=team]])
    removeSubTemplate(itemEid, "user_point_entities_tracker")

[es(tag=(server, net), no_order, on_appear)]
def tell_vehicle_its_marked(evt : Event; userPointVehicleTargetEid : EntityId)
  let newVehicleTemplate : string = add_sub_template_name(userPointVehicleTargetEid, "marked_vehicle")
  if !empty(newVehicleTemplate)
    reCreateEntityFrom(userPointVehicleTargetEid, newVehicleTemplate)

[es(tag=(server, net), no_order, on_disappear)]
def tell_vehicle_its_not_marked(evt : Event; userPointVehicleTargetEid : EntityId)
  let newVehicleTemplate : string = remove_sub_template_name(userPointVehicleTargetEid, "marked_vehicle")
  if !empty(newVehicleTemplate)
    reCreateEntityFrom(userPointVehicleTargetEid, newVehicleTemplate)

[es(tag=server, REQUIRE=deadEntity, on_appear)]
def vehicle_die_user_point_remove_es(evt : Event; eid aka vehicle_eid : EntityId)
  query() <| $ [es] (eid : EntityId; userPointVehicleTargetEid : EntityId; target : EntityId = INVALID_ENTITY_ID)
    if userPointVehicleTargetEid == vehicle_eid
      destroy_point(eid, target)
