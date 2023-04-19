require ecs
require math.base
require game.es.events
require AnimV20
require DngHuman
require GamePhys
require Dacoll
require common_shooter.es.render.animation_common
require common_shooter.events_common_shooter
require game.es.vehicle.vehicle_events
require DagorMath

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
      if human_freefall__gameEffect == INVALID_ENTITY_ID
        human_freefall__gameEffect = createEntity(human_freefall__animationTemplate) <| $(var init : ComponentsInitializer)
          set(init, "game_effect__attachedTo", evt.incomer)
      else
        set(human_freefall__gameEffect, "game_effect__attachedTo", evt.incomer)

[es(tag=gameClient, before=human_anim_es, REQUIRE=paratroopersAircraft)]
def paratroopers_freefall_begin_on_plane_left(evt : EventEnterVehicle)
  if evt.enter
    return

  query(evt.incomer) <| $ [es] (human_freefall__gameEffect : EntityId;
                                animchar : AnimcharBaseComponent;
                                var human_freefall__isFreefall : bool&)
    let animGraph = animchar.animGraph
    if human_freefall__gameEffect == INVALID_ENTITY_ID || animGraph == null
      return
    human_freefall__isFreefall = true
    query(human_freefall__gameEffect) <| $ [es] (game_effect__forceAnimState : string;
                                                 var game_effect__attachedTo : EntityId&;
                                                 var game_effect__forceAnimStateId : int&)
      game_effect__attachedTo = evt.incomer
      game_effect__forceAnimStateId = anim_graph_getStateIdx(*animGraph, game_effect__forceAnimState)
      set_human_anim_state(evt.incomer, game_effect__forceAnimStateId)

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
                        horizontal_air_resistance__accel : float;
                        var horizontal_air_resistance__isOn : bool&;
                        var human_net_phys : HumanActor&)
  if !human_freefall__isFreefall
    return
  assume curVelocity = human_net_phys.phys.currentState.velocity
  if horizontal_air_resistance__isOn
    let horizontalVelocity = float3(curVelocity.x, 0., curVelocity.z)
    let horizontalSpeed = length(horizontalVelocity)
    let horizontalDir = horizontalVelocity * safeinv(horizontalSpeed)
    let horizSpeedAfterAccel = horizontalSpeed - evt.dt * horizontal_air_resistance__accel
    if horizSpeedAfterAccel < 0.
      horizontal_air_resistance__isOn = false
    else
      curVelocity += horizontalDir * (horizSpeedAfterAccel - horizontalSpeed)

  if curVelocity.y >= human_freefall__criticalAirSpeed
    let startVelocity = curVelocity.y + gravity() * evt.dt
    let velNorm = sign(startVelocity)
    let velocitySq = square(min(startVelocity, human_freefall__criticalAirSpeed * 2.0f))
    let accelY = human_freefall__airResistance * velocitySq * velNorm * evt.dt
    curVelocity.y -= accelY

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
