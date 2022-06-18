require ecs
require math.base
require game.es.events
require game.es.game_effect_common
require game.events_game
require app
require EnlistedHuman


[es(tag=server, on_appear)]
def game_effect_set_ignore_objects(evt : Event;
                                   ignoreObjs__eids : EidList;
                                   var game_effect__ignoreObjsEids : EidList&)
  game_effect__ignoreObjsEids := ignoreObjs__eids


[es(tag=server, REQUIRE=game_effect__applyOnFirstContact)]
def game_effect_first_contact_perk(evt : EventFirstContact; eid : EntityId; game_effect__perkName : string; transform : float3x4; game_effect__radius : float;
                                   game_effect__perkTime : float; game_effect__perkEntityTemplate : string; game_effect__ignoreObjsEids : EidList?)
  let queryPos = transform[3] - normalize(evt.velocity) * 0.1
  for_each_human_in_effect_radius(queryPos, game_effect__radius, game_effect__ignoreObjsEids) <| $(human_eid : EntityId)
    let curTime = get_sync_time()
    createEntity(game_effect__perkEntityTemplate) <| $(var init : ComponentsInitializer)
      set(init, "game_effect__perk__target", human_eid)
      set(init, "game_effect__perk__startAtTime", curTime)
      set(init, "game_effect__perk__endAtTime", curTime + game_effect__perkTime)
      set(init, "game_effect__perkName", game_effect__perkName)
      set(init, "transform", transform)
  destroyEntity(eid)

[es(tag=server, REQUIRE=game_effect__applyOnFirstContact, REQUIRE_NOT=trigger__customSpawn)]
def game_effect_first_contact_create_entity(evt : EventFirstContact; eid : EntityId; trigger__entitySpawnTemplate : string; transform : float3x4;
                                            trigger__entitySpawnTransform : float3x4)
  var resTm = transform * trigger__entitySpawnTransform
  let offsetStep = normalize(evt.velocity) * 0.5
  var pos : float3
  for i in range(1, 5)
    pos = resTm[3] - offsetStep * float(i)
    if adjust_entity_spawn_position(pos, 0.8, 8, 0.1)
      break;
  resTm[3] = pos
  createEntity(trigger__entitySpawnTemplate) <| $(var init : ComponentsInitializer)
    set(init, "transform", resTm)
  destroyEntity(eid)

[es(tag=server, REQUIRE=game_effect__applyOnFirstContact)]
def game_effect_first_contact_push(evt : EventFirstContact; eid : EntityId;
                                   transform : float3x4;
                                   game_effect__ignoreObjsEids : EidList?;
                                   game_effect__pushSpeed : float;
                                   game_effect__radius : float;
                                   game_effect__scaleWithRadius : bool = false;
                                   game_effect__scalesPositivelyWithRadius : bool = false)
  let queryPos = transform[3] - normalize(evt.velocity) * 0.1
  for_each_human_in_effect_radius(queryPos, game_effect__radius, game_effect__ignoreObjsEids) <| $(human_eid : EntityId)
    var torso : float3
    var hasTorso = false
    query(human_eid) <| $ [es] (human_net_phys : HumanActor)
      torso = human_net_phys.phys.currentState.torsoCollisionTmPos
      hasTorso = true
    if !hasTorso
      query(human_eid) <| $ [es] (nphys__ccdOffset : float3; transform : float3x4)
        torso = transform * nphys__ccdOffset
        hasTorso = true
    if hasTorso
      var pushFrom = transform[3]
      pushFrom.y = min(pushFrom.y, torso.y)
      let direction = normalize(torso - pushFrom)

      var strength = 1.0
      if game_effect__scaleWithRadius
        if game_effect__scalesPositivelyWithRadius
          strength = lerp(0.0, 1.0, distance(pushFrom, torso) / game_effect__radius)
        else
          strength = lerp(1.0, 0.0, distance(pushFrom, torso) / game_effect__radius)
      sendEvent(human_eid, [[CmdPushPhys vel=direction * game_effect__pushSpeed * strength, push_immunity=0f]])
  destroyEntity(eid)

