module aircraft_common shared
require ecs
require Plane
require EnlistedPlane
require dm
require EnlistedDm
require game.es.events
require game.es.vehicle.vehicle_events
require math.base
require DagorMath
require GamePhys
require CollRes

let private ALL_ENGINES = -1

def repair_plane(eid : EntityId;
                 var plane_net_phys : PlaneActor&;
                 var damage_model : DamageModel&;
                 var fire_protection : FireProtection&;
                 var meta_parts_state : MetaPartsState&)
  assume phys = plane_net_phys.phys
  sendEventImmediate(eid, [[CmdStopBurn]])
  sendEventImmediate(eid, [[CmdRestore]])
  for part in damage_model.dmData.parts
    part.state = DamagePartState DP_STATE_NORMAL
    part.relHpFixed = uint16(MAX_REL_HP_FIXED)
  for state in meta_parts_state.state
    state |> metapart_reset()
  for part in fire_protection
    part.hpFixed = uint16(part.maxHp > 0.0 ? MAX_REL_HP_FIXED : 0)

  phys |> flight_model_repair()
  sendEvent(eid, [[EventOnRepaired eid=INVALID_ENTITY_ID]])

def teleport_plane(teleport_tm : float3x4;
                   collres : CollisionResource;
                   var plane_net_phys : PlaneActor&)
  assume phys = plane_net_phys.phys

  let pos = teleport_tm[3]
  let dir = normalize_default(teleport_tm[0], float3(1, 0, 0))

  let dirQuat = dir_to_quat(dir)

  if phys.EI != null
    assume propulsion = *phys.EI
    propulsion |> propulsion_setEnginesOmega(0.0)
  phys |> flight_model_forcePower(0.0, ALL_ENGINES)
  phys |> flight_model_forceLeftAndRightBrakeControls(1.0)
  phys |> flight_model_forceGear(1.0)

  phys.currentState.location.O |> orient_setQuat(dirQuat)
  phys.currentState.location.P = DPoint3(pos)

  using(collres) <| $(var context : PlanePhysCollisionContext#)
    let speed = float3()
    if phys |> flight_model_setupOnGround(context, true, speed)
      var physTm : float3x4
      phys.currentState.location |> location_toTM(physTm)
      plane_net_phys |> plane_actor_teleportTo(physTm, true)
