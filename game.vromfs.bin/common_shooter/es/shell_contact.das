require ecs
require math
require math.base
require DagorMath
require EnlistedPhysObj
require game.es.events
require DaWeaponProps
require common_shooter.events_common_shooter
require Dacoll


def explode_shell(eid : EntityId;
                  curTime : float;
                  phys_obj_net_phys : PhysObjActor;
                  var shell__active : bool&;
                  var shell__launchTime : float&;
                  shell__fuseTime : float;
                  shell__cleanupTime : float;
                  use_contact_point : bool = true;
                  shell__minPrevPosToContactDistance : float = 0.1;
                  shell__minContactDirDeviationCos : float = 0.999)
  shell__active = false
  if curTime >= shell__launchTime + shell__fuseTime
    var prevPos = float3(phys_obj_net_phys.phys.previousState.location.P)
    let contact = (use_contact_point ? phys_obj_net_phys.phys.currentState.contactPoint :
                                       float3(phys_obj_net_phys.phys.currentState.location.P));
    let vel = phys_obj_net_phys.phys.currentState.velocity

    // if prevPos and contact point are very close, we may have wrong direction prevPos -> contact
    if distance_sq(contact, prevPos) < square(shell__minPrevPosToContactDistance)
      let contactDir = normalize(contact - prevPos)
      let shellDir = normalize(vel)
      if dot(contactDir, shellDir) < shell__minContactDirDeviationCos
        prevPos = contact - shellDir * shell__minPrevPosToContactDistance
    sendEvent(eid, [[CmdShellExplode position=contact, prevPos=prevPos, vel=vel]])
  else
    sendEvent(eid, [[CmdBodyCleanup time=shell__cleanupTime]])


[es(REQUIRE=shell__explodeOnContact)]
def explode_shell_on_water_contact(evt : CmdPostPhysUpdate;
                                   eid : EntityId;
                                   phys_obj_net_phys : PhysObjActor;
                                   shell__isUnderwater : bool;
                                   var shell__active : bool&;
                                   var shell__launchTime : float&;
                                   shell__fuseTime : float = 0.0;
                                   shell__cleanupTime : float = 5.0)
  if !shell__active || !shell__isUnderwater
    return
  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.0
    shell__launchTime = curTime
  explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime, false)


[es(REQUIRE=shell__explodeOnContact)]
def explode_on_contact_shell_contact(evt : CmdPostPhysUpdate;
                                     eid : EntityId;
                                     phys_obj_net_phys : PhysObjActor;
                                     var shell__active : bool&;
                                     var shell__launchTime : float&;
                                     shell__fuseTime : float = 0.0;
                                     shell__cleanupTime : float = 5.0)
  if !shell__active
    return
  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.0
    shell__launchTime = curTime
  if !phys_obj_net_phys.phys.currentState.hadContact
    return
  explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime)


[es(REQUIRE=shell__explodeOnSpeedDrop)]
def explode_on_speed_drop_shell_contact(evt : CmdPostPhysUpdate;
                                        eid : EntityId;
                                        phys_obj_net_phys : PhysObjActor;
                                        shell__shell_id__shell_id : int;
                                        shell__activationSpeedDropThreshold : float;
                                        var shell__active : bool&;
                                        var shell__launchTime : float&;
                                        shell__fuseTime : float = 0.0;
                                        shell__cleanupTime : float = 5.0)
  if !shell__active
    return

  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.f
    shell__launchTime = curTime;
  if !phys_obj_net_phys.phys.currentState.hadContact
    return
  if phys_obj_net_phys.phys.hasRiDestroyingCollision
    return

  let vel = phys_obj_net_phys.phys.currentState.velocity
  shell_start_get_props(shell__shell_id__shell_id) <| $(startProps : ShellStartProps)
    if safediv(length(vel), startProps.speed) >= shell__activationSpeedDropThreshold
      return

    explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime)

[es(tag=server, REQUIRE=shell_trigger__requireContact)]
def shell_trigger_require_contact(evt : CmdPostPhysUpdate;
                                  phys_obj_net_phys : PhysObjActor;
                                  var shell_trigger__active : bool&)
  shell_trigger__active = phys_obj_net_phys.phys.currentState.hadContact
