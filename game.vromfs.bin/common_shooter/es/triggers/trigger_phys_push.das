require ecs
require app
require game.vehicle
require game.events_game
require common_shooter.events_common_shooter
require DagorMath
require HumanPhys
require EnlistedHuman
require EnlistedPhysObj
require EnlistedShip
require PhysObj
require Ship

require daslib/array_boost

[es]
def human_phys_push_es(evt : CmdPushPhys;
                       eid : EntityId;
                       var human_net_phys : HumanActor)
  let pushVel = evt.vel
  let pushIgnoreAmount = evt.push_immunity
  let pushSpd = length(pushVel)
  var pushDir = pushVel * safeinv(pushSpd)
  let dirToNormalDot = dot(pushDir, human_net_phys.phys.currentState.walkNormal)
  if dirToNormalDot < 0.0
    pushDir = pushDir - 2.0 * dirToNormalDot * human_net_phys.phys.currentState.walkNormal
  let curProj = dot(human_net_phys.phys.currentState.velocity, pushDir)
  if curProj < pushSpd
    human_net_phys.phys.currentState.velocity += pushDir * (pushSpd - max(curProj, 0.0))
    human_net_phys.phys.currentState.isInAirHistory = uint8(int(human_net_phys.phys.currentState.isInAirHistory) | 15)
    human_net_phys.phys.currentState.deltaVelIgnoreAmount += pushIgnoreAmount
    let knockBackTimer = 0.6 // TODO: move value to human_net_phys.phys and add something like phys.knockback() function which do just this?
    human_net_phys.phys.currentState.knockBackTimer = knockBackTimer
    human_net_phys.phys |> human_phys_wakeUp()
    human_net_phys.phys |> human_phys_rescheduleAuthorityApprovedSend()
    sendEvent(eid, [[CmdDetachAttachedGun]])


[es]
def physobj_push_es(evt : CmdPushPhys;
                    var phys_obj_net_phys : PhysObjActor)
  let pushVel = evt.vel
  let pushSpd = length(pushVel)
  let pushDir = pushVel * safeinv(pushSpd)
  let curProj = dot(phys_obj_net_phys.phys.currentState.velocity, pushDir)
  phys_obj_net_phys.phys.currentState.velocity += pushDir * (pushSpd - max(curProj, 0.0))
  phys_obj_net_phys.phys |> wakeUp()
  phys_obj_net_phys.phys |> phys_obj_rescheduleAuthorityApprovedSend()


[es]
def vehicle_phys_push_es(evt : CmdVehiclePushPhys;
                         var vehicle_net_phys : VehiclePhysActor)
  if !empty(vehicle_net_phys.phys.explosionDamageImpulses)
    return

  let energyScaledDir = evt.energyScaledDir
  let arm = evt.arm
  let duration = evt.duration
  let mass = vehicle_net_phys.phys.getMass
  let impulse = energyScaledDir * sqrt(mass)
  let endTime = double(get_sync_time() + duration)

  vehicle_net_phys.phys.explosionDamageImpulses |> emplace(
    [[VehiclePhysExplosionDamageImpulse endTime=endTime,
                                        impulse=impulse,
                                        arm=arm]])
  vehicle_net_phys.phys |> wakeUp()


[es]
def ship_phys_push_es(evt : CmdVehiclePushPhys;
                      transform : float3x4;
                      var ship_net_phys : ShipActor;
                      var auto_anchor__nextAnchorTime : float?)
  if !empty(ship_net_phys.phys.explosionDamageImpulses)
    return

  let energyScaledDir = evt.energyScaledDir
  let arm = evt.arm
  let duration = evt.duration
  ship_net_phys.phys |> ship_phys_set_anchor(false)
  let itm = inverse(transform)
  let mass = ship_net_phys.phys.getMass
  let dir = rotate(itm, (energyScaledDir * sqrt(mass)))
  let impulse = dir * ship_net_phys.phys.timeStep
  let endTime = double(get_sync_time() + duration)

  ship_net_phys.phys.explosionDamageImpulses |> emplace(
    [[ShipPhysExplosionDamageImpulse endTime=endTime,
                                     impulse=impulse,
                                     arm=(itm * arm)]])
  ship_net_phys.phys |> ship_phys_wake_up()

  if auto_anchor__nextAnchorTime != null
    *auto_anchor__nextAnchorTime = 0.0