require app
require DagorSystem
require ecs
require EnlistedActor
require EnlistedCamera
require game.es.camera_common
require game.es.player_common
require game.es.player_events
require game.events_game
require level
require EnlistedNet
require player
require strings
require replay

def possessLocalPlayerIfLevelLoaded(to_possess : EntityId)
  assert(to_possess != INVALID_ENTITY_ID)

  let localPlayerEid : EntityId = get_local_player_eid()
  assert(localPlayerEid != INVALID_ENTITY_ID)
  if localPlayerEid == INVALID_ENTITY_ID
    return

  if is_level_loaded()
    sendEventImmediate(localPlayerEid, [[PossessTargetByPlayer target=to_possess]])
  else
    setOptional(to_possess, "possessedByPlr", localPlayerEid)
    set(localPlayerEid, "possessed", to_possess) // possess() it later, when level loaded (for camera)

def unpossess_entity(eid : EntityId) : void
  var obj : BasePhysActor? = get_phys_actor(eid)
  let physType : string = obj != null ? obj.physTypeStr : get_string(eid, "phys__physTypeStr", "")
  if !empty(physType)
    let newActorTemplName : string = remove_sub_template_name(eid, "{physType}_hero_components_local")
    if !empty(newActorTemplName) // otherwise entity scheduled to be destroyed?
      reCreateEntityFrom(eid, remove_sub_template_name(newActorTemplName, "observed_local"))
  if obj == null
    return
  *obj |> base_phys_actor_resetAAS() // Don't try to process too old AAS when we possess this entity again
  if !is_server()
    *obj |> base_phys_actor_setRoleAndTickrateType(NetRole ROLE_REMOTELY_CONTROLLED_SHADOW, PhysTickRateType LowFreq)

[es(tag=gameClient, REQUIRE=player, before=player_possess)]
def player_possess_camera(evt : PossessTargetByPlayer; eid : EntityId; connid : int; is_local : bool; possessed : EntityId)
  let neid = evt.target
  verify(neid == INVALID_ENTITY_ID || doesEntityExist(neid))

  let oldPossessed : EntityId = possessed
  var actor : BasePhysActor? = get_phys_actor(neid)

  print("player_possess_camera {int(uint(eid))}: conn=#{connid} {int(uint(oldPossessed))} -> {int(uint(neid))}")

  if is_local
    if is_server() && oldPossessed != neid && doesEntityExist(oldPossessed) // For the offline game, where the PossessHero isn't sent
      unpossess_entity(oldPossessed)
    if neid == INVALID_ENTITY_ID
      send_enable_spectator_for_player(eid)
    elif actor != null
      setOptional(neid, "possessedByPlr", eid) // so the actor may "find" its player even before possessedByPlr is replicated from server
      // Note: we intentionally check for sub-template names here (as opposed to comp existence)
      // because entity might still be in creation queue
      let futEntTemplName : string = getEntityFutureTemplateName(neid)
      let compHeroName : string = "+{actor.physTypeStr}_hero_components_local"
      let hasHeroComp : bool = find(futEntTemplName, compHeroName) != -1
      let hasObserved : bool = find(futEntTemplName, "+observed_local") != -1
      if !hasHeroComp || !hasObserved
        let newActorTemplName : string = "{futEntTemplName}{hasHeroComp ? "" : compHeroName}{hasObserved ? "" : "+observed_local"}"
        let finalizeCreation <- @ <| (actor_eid : EntityId)
          if doesEntityExist(eid)
            possess_entity_camera_smooth(actor_eid, 0, eid, INVALID_ENTITY_ID)
        neid |> reCreateEntityFrom(newActorTemplName, finalizeCreation) <| $(var init : ComponentsInitializer)
          set(init, "watchedByPlr", eid)

  query(neid) <| $ [es] (var replication : NetObject&) // TODO: fix this place? query had (tag=netClient) previously which does not work for queries
    if actor != null
      *actor |> base_phys_actor_setRoleAndTickrateType(NetRole ROLE_LOCALLY_CONTROLLED_SHADOW, PhysTickRateType Normal)
    let sconn : IConnection? = get_server_conn()
    if sconn != null
      net_object_setControlledBy(replication, connection_getId(*sconn))

  if is_local && (actor != null || neid == INVALID_ENTITY_ID) // if entity is not created yet, then this event will be emitted when it created
    emit_hero_changed_event(neid)

[es(tag=gameClient)]
def on_possess_hero_msg(evt : PossessHero; eid : EntityId)
  if is_replay_playing()
    return // don't try possess hero in replay
  print("PossessHero {int(uint(eid))} {evt.possess ? "possess" : "unpossess"}")
  if evt.possess
    possessLocalPlayerIfLevelLoaded(eid)
  else
    unpossess_entity(eid)
    emit_hero_changed_event(INVALID_ENTITY_ID) // for cases when new hero would not be recieved
