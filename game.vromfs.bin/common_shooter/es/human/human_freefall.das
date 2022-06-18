require ecs
require math.base
require game.es.events
require EnlistedHuman
require GamePhys
require Dacoll
require common_shooter.events_common_shooter
require game.es.vehicle.vehicle_events


[es(tag=server, REQUIRE=airplane)]
def human_freefall_begin_on_plane_left(evt : EventEnterVehicle)
  if evt.enter
    return

  query(evt.incomer) <| $ [es] (transform : float3x4;
                                human_freefall__minPlaneHeight : float;
                                human_freefall__animationTemplate : string;
                                var human_freefall__isFreefall : bool&;
                                var human_freefall__gameEffect : EntityId&)
    let posXZ = transform[3].xz
    let heightAboveGround = transform[3].y - traceht_lmesh(posXZ)

    if heightAboveGround > human_freefall__minPlaneHeight
      human_freefall__isFreefall = true
      human_freefall__gameEffect = createEntity(human_freefall__animationTemplate) <| $(var init : ComponentsInitializer)
        set(init, "game_effect__attachedTo", evt.incomer)

[es(tag=server, no_order)]
def human_freefall_begin(info : UpdateStageInfoAct;
                         eid : EntityId;
                         human_net_phys : HumanActor&;
                         human_net_phys__isInAir : bool;
                         isInVehicle : bool;
                         human_jetpack__enabled : bool = false;
                         human_freefall__criticalAirSpeed : float;
                         human_freefall__animationTemplate : string;
                         human_freefall__canFreefall : bool;
                         var human_freefall__isFreefall : bool&;
                         var human_freefall__gameEffect : EntityId&)
  if !human_freefall__canFreefall || !human_net_phys__isInAir || human_freefall__isFreefall || isInVehicle || human_jetpack__enabled
    return
  if abs(human_net_phys.phys.currentState.velocity.y) < human_freefall__criticalAirSpeed
    return

  human_freefall__isFreefall = true
  human_freefall__gameEffect = createEntity(human_freefall__animationTemplate) <| $(var init : ComponentsInitializer)
    set(init, "game_effect__attachedTo", eid)

[es]
def human_freefall_phys(evt : CmdPostPhysUpdate;
                        human_freefall__isFreefall : bool;
                        human_freefall__criticalAirSpeed : float;
                        human_freefall__airResistance : float;
                        var human_net_phys : HumanActor&)
  if !human_freefall__isFreefall
    return

  if length_sq(human_net_phys.phys.currentState.velocity) >= square(human_freefall__criticalAirSpeed)
    let startVelocity = human_net_phys.phys.currentState.velocity + float3(0.0, gravity() * evt.dt, 0.0)
    let velNorm = normalize(startVelocity)
    let lenSq = min(length_sq(startVelocity), square(human_freefall__criticalAirSpeed * 2.0f))
    let accel = (human_freefall__airResistance * lenSq * velNorm) * evt.dt
    human_net_phys.phys.currentState.velocity -= accel

def end_freefall(var human_freefall__isFreefall : bool&; var human_freefall__gameEffect : EntityId&)
  human_freefall__isFreefall = false
  destroyEntity(human_freefall__gameEffect)
  human_freefall__gameEffect = INVALID_ENTITY_ID

[es(tag=server, track=human_net_phys__isInAir)]
def human_freefall_end_on_land(evt : Event;
                               human_net_phys__isInAir : bool;
                               var human_freefall__isFreefall : bool&;
                               var human_freefall__gameEffect : EntityId&)
  if human_freefall__isFreefall && !human_net_phys__isInAir
    end_freefall(human_freefall__isFreefall, human_freefall__gameEffect)

[es(tag=server)]
def human_freefall_end_on_cmd(evt : CmdHumanEndFreefall;
                              var human_freefall__isFreefall : bool&;
                              var human_freefall__gameEffect : EntityId&)
  end_freefall(human_freefall__isFreefall, human_freefall__gameEffect)
