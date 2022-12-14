require ecs
require EnlistedNet
require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require game.utils.team
require Dacoll
require DagorMath
require CollRes
require PhysMat
require strings
require app
require common_shooter.es.user_points_common


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

def on_cmd_set_mark(player, possessed : EntityId; always_enemy : bool)
  let isExistsAndAlive = possessed |> get_bool("isAlive") ?? false // as possessed entity could be invalid entity at this poit and we should use spectator in this case
  if isExistsAndAlive
    query(possessed) <| $ [es] (human__aimTm : float3x4;
                                human_weap__currentGunEid : EntityId;
                                human_net_phys__isAiming : bool;
                                camera__lookDir : float3 = float3())
      find_query() <| $ [es] (ui_crosshair_state__isAiming : bool)
        let markType = ui_crosshair_state__isAiming || always_enemy ? "enemy" : "main"
        let aimRayMatId = get_int(human_weap__currentGunEid, "gun__aimRayMatId") ?? PHYSMAT_INVALID
        set_mark(markType, player, human__aimTm[3], human_net_phys__isAiming ? human__aimTm[0] : camera__lookDir, aimRayMatId)
        return true
  else
    find_query() <| $ [es(REQUIRE=spectator__target)] (transform : float3x4)
      let markType = always_enemy ? "enemy" : "main"
      set_mark(markType, player, transform[3], transform[2])
      return true

[es(tag = gameClient, on_event=CmdSetMarkEnemy)]
def on_cmd_set_mark_enemy(evt : Event; eid, possessed : EntityId)
  on_cmd_set_mark(eid, possessed, true)

[es(tag = gameClient, on_event=CmdSetMarkMain)]
def on_cmd_set_mark_main(evt : Event; eid, possessed : EntityId)
  on_cmd_set_mark(eid, possessed, false)

[es(tag = gameClient)]
def on_cmd_create_map_point(evt : CmdCreateMapPoint; eid : EntityId; possessed : EntityId)
  let len = 500.0
  let x = evt.x
  let z = evt.z
  var upmostPos = float3(x, len, z)
  let traceDir = float3(0.0, -1.0, 0.0)
  var norm : float3
  var t = len
  var pmid : int
  var rendInstDesc = RendInstDesc()
  query(possessed) <| $ [es] (human_weap__currentGunEid : EntityId)
    var aimRayMatId = PHYSMAT_INVALID
    query(human_weap__currentGunEid) <| $ [es] (gun__aimRayMatId : int)
      aimRayMatId = gun__aimRayMatId

    traceray_normalized(upmostPos, traceDir, t, pmid, norm, ETF_DEFAULT, rendInstDesc, aimRayMatId)
    upmostPos.y = t >= 0.0 ? len - t : 0.0
  send_net_event(eid, [[CmdCreateMapUserPoint pos = upmostPos, dir = traceDir, norm = norm, item_name = "way_point", markOwnerEid = INVALID_ENTITY_ID ]])

[es(tag=server)]
def clear_attached_points_es(evt : EventOnLootPickup; team : int)
  let itemEid = evt.itemEid
  if itemEid |> has("userPointTracker")
    broadcastEvent([[CmdClearAllAttachedUserPoint target=itemEid, team=team]])
    removeSubTemplate(itemEid, "user_point_entities_tracker")

[es(tag=gameClient, no_order, REQUIRE_NOT=userPointVehicleOffset)]
def userpoint_update_vehicle_marker_position(act : UpdateStageInfoAct; userPointVehicleTargetEid : EntityId; var transform aka userpoint_transform : float3x4&)
  query(userPointVehicleTargetEid) <| $ [es(REQUIRE=vehicle)] (transform : float3x4; collres : CollisionResource)
    userpoint_transform[3] = transform[3] + BBox3(collres.vFullBBox).center

[es(tag=gameClient, no_order)]
def userpoint_update_point_on_vehicle_marker_position(act : UpdateStageInfoAct;
                                                      userPointVehicleTargetEid : EntityId;
                                                      var transform aka userpoint_transform : float3x4&;
                                                      userPointVehicleOffset : float3)
  query(userPointVehicleTargetEid) <| $ [es(REQUIRE=vehicle)] (transform : float3x4)
    userpoint_transform[3] = transform[3] + userPointVehicleOffset

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
