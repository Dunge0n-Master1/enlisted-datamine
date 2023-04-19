require ecs
require app
require game.es.events
require DngPhysObj
require common_shooter.es.human.human_parachute_common

[es(tag=server, on_appear, REQUIRE=deadEntity)]
def parachute_destroy_on_die(evt : Event;
                             var human_parachute__eid : EntityId&)
  if !!human_parachute__eid
    destroyEntity(human_parachute__eid)
    human_parachute__eid = INVALID_ENTITY_ID

[es(tag=server, on_appear)]
def parachute_create_on_init(evt : Event;
                             eid : EntityId;
                             parachute__template : string)
  parachute_create_for_eid(eid, parachute__template)

[es(tag=server, REQUIRE=parachuteDeployed, on_disappear)]
def parachute_mark_to_destroy(evt : Event;
                              parachute__deleteAfterTime : float;
                              var parachute__deleteAtTime : float&)
  parachute__deleteAtTime = get_sync_time() + parachute__deleteAfterTime

[es(tag=server, REQUIRE_NOT=parachuteDeployed, no_order)]
def parachute_destroy_after_time(info : UpdateStageInfoAct;
                                 parachute__deleteAtTime : float;
                                 var human_parachute__eid : EntityId&)
  if parachute__deleteAtTime > 0. && info.curTime > parachute__deleteAtTime
    destroyEntity(human_parachute__eid)
    human_parachute__eid = INVALID_ENTITY_ID

[es(on_appear, REQUIRE=parachute)]
def parachute_attach_on_create(evt : Event;
                               eid : EntityId;
                               item__ownerEid : EntityId)
  query(item__ownerEid) <| $ [es] (var human_parachute__eid : EntityId&)
    human_parachute__eid = eid
  addSubTemplate(item__ownerEid, "has_parachute")

[es(on_disappear, REQUIRE=parachute)]
def parachute_on_destroy(evt : Event; item__ownerEid : EntityId)
  removeSubTemplate(item__ownerEid, "has_parachute")

[es(tag=server, REQUIRE=hasParachute)] // TODO: combine with human_parachute_deploy
def parachute_auto_deploy(evt : CmdPostPhysUpdate;
                          human_parachute__eid : EntityId;
                          transform : float3x4;
                          phys_obj_net_phys : PhysObjActor;
                          var parachute__autoDeployHeight : float&)
  query(human_parachute__eid) <| $ [es] (var parachute__deployed : bool&;
                                         var parachute__deployedAtTime : float&)
    let altitude = get_parachute_altitude(transform[3])
    if !parachute__deployed && parachute__autoDeployHeight > 0.0 && altitude < parachute__autoDeployHeight
      parachute__deployed = true
      parachute__autoDeployHeight = -1.
      parachute__deployedAtTime = get_sync_time()

    if parachute__deployed && phys_obj_net_phys.phys.currentState.hadContact
      parachute__deployed = false

[es(REQUIRE=(hasParachute, parachuteDeployed))]
def phys_obj_parachute(evt : CmdPostPhysUpdate;
                       human_parachute__eid : EntityId;
                       var phys_obj_net_phys : PhysObjActor)
  assume velocity = phys_obj_net_phys.phys.currentState.velocity
  velocity = parachute_update_phys(human_parachute__eid, velocity, evt.dt)
