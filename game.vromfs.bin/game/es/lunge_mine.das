require ecs
require game.events_game
require DngWeapon
require DaWeaponProps
require app
require game.es.mine_common
require DngHuman
require HumanPhys
require Action
require game.es.inventory_common
require game.es.events
require DagorMath
require common_shooter.events_common_shooter
require DngPhysObj

let MINE_POSSIBLE_SLOTS = [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY;
    HUWeaponSlots EWS_TERTIARY; HUWeaponSlots EWS_MELEE; HUWeaponSlots EWS_SPECIAL]]

let MINE_ACTIONS = [[string "crawl_melee"; "stand_melee"]]

def private activate_lunge_mine(pos : float3;
                                owner : EntityId;
                                lunge_mine__activator : string;
                                var lunge_mine__active : bool&;
                                shoot_dir : float3;
                                detonate_fx : string)
  if lunge_mine__active
    return
  lunge_mine__active = true
  var tm : float3x4
  identity(tm)
  tm[0] = normalize(shoot_dir)
  tm[2] = normalize(cross(tm[0], tm[1]))
  tm[1] = normalize(cross(tm[2], tm[0]))
  tm[3] = pos
  createEntity(detonate_fx) <| $(var init)
    set(init, "transform", tm)
  detonate_mine(INVALID_ENTITY_ID, lunge_mine__activator, owner, tm)

[es(tag=server)]
def lunge_mine_hit_ri_es(evt : CmdRendinstDamage;
                         eid : EntityId;
                         human_net_phys : HumanActor;
                         human_weap__currentGunEid : EntityId)
  assume appliedCt = human_net_phys.phys.appliedCT
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=lunge_mine)] (var lunge_mine__active : bool&;
                                                                  var blockShoot : bool&;
                                                                  lunge_mine__stepback : float;
                                                                  lunge_mine__activator : string;
                                                                  lunge_mine__detonateFx : string)
    let stepback = appliedCt.wishShootDir * lunge_mine__stepback
    activate_lunge_mine(evt.pos - stepback, eid, lunge_mine__activator, lunge_mine__active, appliedCt.wishShootDir,
      lunge_mine__detonateFx)
    blockShoot = lunge_mine__active

[es(tag=server)]
def lunge_mine_hit_target_es(evt : EventMeleeAttackHit;
                             eid : EntityId;
                             human_net_phys : HumanActor;
                             human_weap__currentGunEid : EntityId)
  assume appliedCt = human_net_phys.phys.appliedCT
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=lunge_mine)] (var lunge_mine__active : bool&;
                                                                  var blockShoot : bool&;
                                                                  lunge_mine__stepback : float;
                                                                  lunge_mine__activator : string;
                                                                  lunge_mine__detonateFx : string)
    let stepback = appliedCt.wishShootDir * lunge_mine__stepback
    activate_lunge_mine(evt.pos - stepback, eid, lunge_mine__activator, lunge_mine__active, appliedCt.wishShootDir,
      lunge_mine__detonateFx)
    blockShoot = lunge_mine__active

def private switch_from_lunge_mine(human_weap__gunEids : EidList; var phys : HumanPhys)
  var found = false
  for slotId in MINE_POSSIBLE_SLOTS
    query(human_weap__gunEids[int(slotId)]) <| $ [es] (lunge_mine__active : bool = false)
      if !lunge_mine__active
        phys.producedCT |> set_chosen_weapon(slotId)
        found = true
    if found
      return true
  return false

def private is_anim_progress_valid_to_change_weapon(phys : HumanPhys; slot : int)
  assume curWeapState = phys.currentState.weapEquipState
  assume prevWeapState = phys.previousState.weapEquipState
  if int(curWeapState.curSlot) != slot && int(curWeapState.nextSlot) != slot
    return false

  let prevStateProgress = phys.previousState.weapEquipState.progress
  let curStateProgress = phys.currentState.weapEquipState.progress
  let curState = phys.currentState.weapEquipState.curState
  return curStateProgress < prevStateProgress && curState == HUWeaponEquipState EES_EQUIPING

[es(tag=server, track=human_weap__currentGunEid)]
def remove_lunge_mine_from_inv_es(evt : Event;
                                  human_weap__currentGunEid : EntityId;
                                  human_weap__currentGunSlot : int;
                                  var itemContainer : EidList;
                                  var human_weap__gunEids : EidList&)
  if has(human_weap__currentGunEid, "lunge_mine")
    return

  for slotId in MINE_POSSIBLE_SLOTS
    if human_weap__currentGunSlot == int(slotId)
      continue
    assume mineEid = human_weap__gunEids[int(slotId)]
    query(mineEid) <| $ [es(REQUIRE=lunge_mine)] (lunge_mine__active : bool)
      if lunge_mine__active
        remove_item_from_cont(mineEid, itemContainer)
        destroyEntity(mineEid)
        human_weap__gunEids[int(slotId)] = INVALID_ENTITY_ID

[es(tag=gameClient, no_order, REQUIRE=watchedPlayerItem)]
def lunge_mine_remove_on_active_es(info : UpdateStageInfoAct;
                                   eid : EntityId;
                                   gun__owner : EntityId;
                                   lunge_mine__active : bool;
                                   var animchar_render__enabled : bool&;
                                   lunge_mine__actionHidePercent : float = 0.5)
  if !lunge_mine__active
    return
  query(gun__owner) <| $ [es(REQUIRE=hero)] (action__running : bool;
                                             human_weap__gunEids : EidList;
                                             actions : EntityActions;
                                             var human_net_phys : HumanActor&)
    if animchar_render__enabled && action__running
      for act in actions.actions
        let index = find_index(MINE_ACTIONS, string(act.name))
        if index >= 0
          if act.timer > 0. && safediv(act.timer, act.actionTime) <= lunge_mine__actionHidePercent
            animchar_render__enabled = false
          break

    if action__running
      return

    let slotId = find_index(each(human_weap__gunEids), eid)
    if slotId >= 0 && !is_anim_progress_valid_to_change_weapon(human_net_phys.phys, slotId)
      switch_from_lunge_mine(human_weap__gunEids, human_net_phys.phys)

[es(tag=server, REQUIRE=lungeMine, before=explode_on_contact_shell_contact)]
def lunge_mine_destroy_by_distance(evt : CmdPostPhysUpdate;
                                   eid : EntityId;
                                   shell__maxDistanceSq : float;
                                   phys_obj_net_phys : PhysObjActor;
                                   shell__startPos : float3;
                                   var shell__active : bool&)
  // A lunge mine is created with initial velocity so that it flies toward the target and explodes on contact.
  // There is a chance that the lunge mine will miss a small target (human) and fly past it.
  // So, we keep it from flying too far and make it explode.
  if !shell__active
    return
  let curPos = float3(phys_obj_net_phys.phys.currentState.location.P)
  let path = curPos - shell__startPos
  let distance = length_sq(path)
  if distance > shell__maxDistanceSq
    let dir = normalize(path)
    let posCapped = shell__startPos + sqrt(shell__maxDistanceSq) * dir
    sendEvent(eid, [[CmdShellExplode position=posCapped, prevPos = posCapped, vel = float3()]])
    shell__active = false

[es(tag=server, REQUIRE=lungeMine, on_appear)]
def init_lunge_mine_start_pos(evt : Event; phys_obj_net_phys : PhysObjActor; var shell__startPos : float3&)
  let curPos = float3(phys_obj_net_phys.phys.currentState.location.P)
  shell__startPos = curPos
