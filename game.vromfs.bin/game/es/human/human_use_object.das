require ecs
require game.es.human.human_use_object_common
require game.es.events
require enlisted.events_enlisted
require math.base
require game.utils.team
require zones
require AnimV20
require GeomNodeTree
require EnlistedWeapon
require EnlistedHuman
require DagorMath
require Grid
require RendInst
require CollRes
require Dacoll
require GridCollision
require common_shooter.es.grenade_thrower_common


[es(tag=server, REQUIRE=human_use_object__selectedObject, REQUIRE_NOT=deadEntity)]
def on_human_use_object_request(evt : HumanUseObjectRequest;
                                eid : EntityId;
                                transform aka user_transform : float3x4;
                                isDowned : bool = false;
                                human_use_object__thresholdDist : float = 12.f)
  if !isDowned
    human_try_use_object(eid, user_transform[3], human_use_object__thresholdDist, evt.objectEid)


[es(on_appear)]
def human_use_object_created_es(evt : Event;
                                animchar : AnimcharBaseComponent;
                                human_use_object__lookNodeName : string;
                                var human_use_object__nodeId : int&)
  if human_use_object__lookNodeName != ""
    human_use_object__nodeId = *animchar.nodeTree |> geomtree_findNodeIndex(human_use_object__lookNodeName)
  else
    human_use_object__nodeId = 0 // Not all code can handle invalid nodeId


[es(REQUIRE=hero)]
def hero_human_pre_use_object_es(info : ParallelUpdateFrameDelayed;
                                 var human_use_object__selectedObject : EntityId&;
                                 var human_use_object__lookAtSelected : bool&;
                                 var human_use_object__lookAtObject : EntityId&;
                                 var customUsePrompt : das_string)
  human_use_object__selectedObject = INVALID_ENTITY_ID
  human_use_object__lookAtSelected = false
  human_use_object__lookAtObject = INVALID_ENTITY_ID
  customUsePrompt := ""


[es(REQUIRE=hero, after=(hero_human_use_delivery_item, hero_human_use_revive_object_es, hero_human_pre_use_object_es), before=hero_human_final_use_object_sync)]
def hero_human_use_current_vehicle_object_es(info : ParallelUpdateFrameDelayed;
                                             isInVehicle : bool = false;
                                             human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                                             var human_use_object__selectedObject : EntityId&;
                                             var human_use_object__lookAtSelected : bool&)
  if !isInVehicle || !human_anim__vehicleSelected
    return
  human_use_object__selectedObject = human_anim__vehicleSelected
  human_use_object__lookAtSelected = true


[es(REQUIRE=hero, after=hero_human_pre_use_object_es, before=hero_human_final_use_object_sync)]
def hero_human_use_grenade_rethrow_object_es(info : ParallelUpdateFrameDelayed;
                                             eid : EntityId;
                                             human_use_object__lockGrenadeRethrowing : bool = false;
                                             var human_use_object__selectedObject : EntityId&)
  // We have something better already
  if human_use_object__selectedObject != INVALID_ENTITY_ID || human_use_object__lockGrenadeRethrowing
    return

  human_use_object__selectedObject = find_rethrowable_grenade(eid)


[es(REQUIRE=hero, after=(hero_human_use_craft_bag, hero_human_use_current_vehicle_object_es, hero_human_pre_use_object_es), before=hero_human_final_use_object_sync)]
def hero_human_use_stationary_gun_object_es(info : ParallelUpdateFrameDelayed;
                                            eid : EntityId;
                                            human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                                            human_use_object__lockStationaryGunUse : bool = false;
                                            var human_use_object__selectedObject : EntityId&)
  if human_use_object__selectedObject != INVALID_ENTITY_ID
    return

  let gunEid = find_gun_to_attach(eid, 2.0, false)
  if gunEid != INVALID_ENTITY_ID
    if !human_use_object__lockStationaryGunUse
      human_use_object__selectedObject = gunEid
  elif human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    human_use_object__selectedObject = human_attached_gun__attachedGunEid