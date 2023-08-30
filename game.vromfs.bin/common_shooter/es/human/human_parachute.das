require ecs
require app
require DngHuman
require game.es.events
require common_shooter.events_common_shooter
require common_shooter.es.human.human_parachute_common
require enlisted.events_enlisted


[es(on_appear, track=parachute__deployed)]
def apply_parachute_deployed_tag(evt : Event;
                                 eid : EntityId;
                                 item__ownerEid : EntityId;
                                 parachute__deployed : bool)
  if parachute__deployed
    addSubTemplate(eid, "parachute_deployed")
    addSubTemplate(item__ownerEid, "parachute_deployed")
  else
    removeSubTemplate(eid, "parachute_deployed")
    removeSubTemplate(item__ownerEid, "parachute_deployed")

  query(item__ownerEid) <| $ [es] (var human_parachute__isDeployed : bool&)
    human_parachute__isDeployed = parachute__deployed


[es(tag=server, no_order, REQUIRE=hasParachute)]
def can_open_parachute(evt : UpdateStageInfoAct;
                       transform : float3x4;
                       isInVehicle : bool;
                       human_net_phys__velocity : float3;
                       human_net_phys__isInAir : bool;
                       human_parachute__minDeployHeight : float;
                       human_parachute__minDeployVelocity : float;
                       var human_parachute__canDeploy : bool&)
  let isFalling = human_net_phys__velocity.y < -human_parachute__minDeployVelocity
  human_parachute__canDeploy = (human_net_phys__isInAir &&
                                !isInVehicle &&
                                isFalling &&
                                get_parachute_altitude(transform[3]) > human_parachute__minDeployHeight)


[es(tag=server, REQUIRE=hasParachute)]
def on_parachute_open_request(evt : HumanRequestParachuteOpen;
                              human_parachute__eid : EntityId;
                              human_parachute__canDeployManually : bool;
                              human_parachute__canDeploy : bool)
  if !human_parachute__canDeployManually || !human_parachute__canDeploy
    return

  query(human_parachute__eid) <| $ [es] (var parachute__deployed : bool&;
                                         var parachute__deployedAtTime : float&)
    parachute__deployed = true
    parachute__deployedAtTime = get_sync_time()


[es(tag=server, before=human_parachute, REQUIRE=hasParachute)]
def human_parachute_deploy(evt : CmdPostPhysUpdate;
                           transform : float3x4;
                           human_parachute__eid : EntityId;
                           human_parachute__canDeploy : bool;
                           human_parachute__autoDeployHeight : float;
                           human_net_phys__isInAir : bool)
  query(human_parachute__eid) <| $ [es] (var parachute__deployed : bool&;
                                         var parachute__deployedAtTime : float&)
    // auto deploy
    if !parachute__deployed && human_parachute__canDeploy && human_parachute__autoDeployHeight > 0.0 && get_parachute_altitude(transform[3]) < human_parachute__autoDeployHeight
      parachute__deployed = true
      parachute__deployedAtTime = get_sync_time()

    if !human_net_phys__isInAir
      parachute__deployed = false


[es(tag=server, on_disappear, REQUIRE=hasParachute)]
def human_parachute_disable_on_death(evt : Event;
                                     human_parachute__eid : EntityId)
  query(human_parachute__eid) <| $ [es] (var parachute__deployed : bool&)
    parachute__deployed = false


[es(after=human_parachute_deploy, REQUIRE=(hasParachute, parachuteDeployed))]
def human_parachute(evt : CmdPostPhysUpdate;
                    human_parachute__eid : EntityId;
                    var human_net_phys : HumanActor)
  assume velocity = human_net_phys.phys.currentState.velocity
  velocity = parachute_update_phys(human_parachute__eid, velocity, evt.dt)

[es(tag=server, on_appear, REQUIRE=parachuteDeployed)]
def human_parachute_disable_freefall_on_deploy(evt : Event;
                                               eid : EntityId;
                                               var human_freefall__canFreefall : bool&)
  human_freefall__canFreefall = false
  sendEventImmediate(eid, [[CmdHumanEndFreefall]])

[es(tag=server, on_disappear, REQUIRE=parachuteDeployed)]
def human_parachute_enable_freefall_on_land(evt : Event;
                                            var human_freefall__canFreefall : bool&)
  human_freefall__canFreefall = true

[es(tag=server, on_appear, REQUIRE=parachuteDeployed)]
def horizontal_air_resistance_turn_off_on_parachute_deployed(evt : Event;
                                                             var horizontal_air_resistance__isOn : bool&)
  horizontal_air_resistance__isOn = false

[es(tag=server, on_appear, REQUIRE=parachuteDeployed)]
def human_parachute_disable_weapons_on_deploy(evt : Event;
                                              eid : EntityId;
                                              human_parachute__hideWeaponAffectTemplate : string;
                                              var human_parachute__hideWeaponAffectEid : EntityId&)
  if human_parachute__hideWeaponAffectEid == INVALID_ENTITY_ID
    human_parachute__hideWeaponAffectEid = createEntity(human_parachute__hideWeaponAffectTemplate) <| $ [es] (init)
      init |> set("game_effect__attachedTo", eid)

[es(tag=server, on_disappear, REQUIRE=parachuteDeployed)]
def human_parachute_enable_weapons_on_land(evt : Event;
                                           var human_parachute__hideWeaponAffectEid : EntityId&)
  destroyEntity(human_parachute__hideWeaponAffectEid)
  human_parachute__hideWeaponAffectEid = INVALID_ENTITY_ID

[es(before=human_weap_phys_es, after=human_weap_block_aim_es, REQUIRE=parachuteDeployed)]
def human_parachute_block_aiming(info : ParallelUpdateFrameDelayed;
                                 var human_weap__blockAiming : bool&)
  human_weap__blockAiming = true
