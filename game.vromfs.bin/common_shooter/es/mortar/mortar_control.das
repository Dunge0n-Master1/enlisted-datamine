require ecs
require Gun
require math
require game.utils.hero
require EnlistedHuman
require game.es.device_state_common
require game.es.events

def manage_mortar_target(human_weap__curGunSlot : int;
                         human_weap__gunEids : ecs::EidList const;
                         human_weap__mortarMode : bool)
  if human_weap__mortarMode
    let alreadyExists = find_query() <| $ [es(REQUIRE=mortar_target)] ()
      return true
    if alreadyExists
      return
    let weapEid = human_weap__gunEids[human_weap__curGunSlot]
    query(weapEid) <| $ [es(REQUIRE=mortar)] (mortar__targetTemplate : string)
      createEntity(mortar__targetTemplate)
  else
    query() <| $ [es(REQUIRE=mortar_target)] (eid : EntityId)
      destroyEntity(eid)

[es(tag=gameClient, REQUIRE=hero, track=human_weap__mortarMode)]
def mortar_target_activator_mode_changed(evt : Event;
                                         human_weap__curGunSlot : int;
                                         human_weap__gunEids : ecs::EidList const;
                                         human_weap__mortarMode : bool)
  manage_mortar_target(human_weap__curGunSlot, human_weap__gunEids, human_weap__mortarMode)

[es(tag=gameClient, REQUIRE=hero)]
def mortar_target_activator_hero_changed(evt : EventHeroChanged)
  query(evt.eid) <| $ [es] (human_weap__curGunSlot : int;
                            human_weap__gunEids : ecs::EidList const;
                            human_weap__mortarMode : bool)
    manage_mortar_target(human_weap__curGunSlot, human_weap__gunEids, human_weap__mortarMode)

[es(tag=gameClient, track=mortar__targetPos)]
def move_mortar_target(evt : Event; mortar__targetPos : float3; gun__owner : ecs::EntityId)
  if !has(gun__owner, "hero")
    return
  query() <| $ [es(REQUIRE=mortar_target)] (var transform : float3x4)
    transform[3] = mortar__targetPos

[es(tag=gameClient, track=human_weap__mortarMode)]
def mortar_init_target_controls(evt : Event;
                                human_net_phys : HumanActor;
                                human_weap__mortarMode : bool;
                                human_weap__curGunSlot : int;
                                human_weap__gunEids : ecs::EidList const)
  if human_weap__mortarMode
    let weapEid = human_weap__gunEids[human_weap__curGunSlot]
    query(weapEid) <| $ [es(REQUIRE=mortar)] (var mortar__targetDistance : float&; var mortar__initDir : float2&; mortar__defaultTargetDistance : float = 30.0)
      mortar__targetDistance = mortar__defaultTargetDistance
      let dir = human_net_phys.phys.producedCT.wishShootDir
      mortar__initDir.x = dir.x
      mortar__initDir.y = dir.z

[es(on_event=CmdPostPhysUpdate)]
def mortar_rotate_body(evt : Event; var human_net_phys : HumanActor; human_weap__mortarMode : bool)
  if human_weap__mortarMode
    let wishShootdir = human_net_phys.phys.appliedCT.wishShootDir
    human_net_phys.phys.currentState.bodyOrientDir = float2(wishShootdir.x, wishShootdir.z);

[es(tag=gameClient, track=(device_anim__state, device_anim__progress))]
def mortar_lock_control(evt : Event;
                        device_anim__state : int;
                        device_anim__progress : float;
                        var mortar__lockedControl : bool&;
                        mortar__lockedProgress : float = 1.0)
  let fireState = int(DeviceAnimState DEVICE_STATE_FIRE)
  mortar__lockedControl = device_anim__state == fireState && device_anim__progress <= mortar__lockedProgress
