require ecs
require ecs.common
require app
require EnlistedNet
require math
require math.base
require common_shooter.events_common_shooter
require common_shooter.es.human.human_gun_common
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require DagorMath
require DagorDataBlock
require Gun
require EnlistedPhys
require EnlistedWeapon
require AnimV20
require HumanPhys
require PhysDecl
require GunAnim
require PhysVars
require AnimatedPhys
require DaWeapons

[es(on_appear)]
def gun_attach__mainSlotId_init(evt : Event;
                                gun_attach__slot : string;
                                var gun_attach__mainSlotId : int&)
  gun_attach__mainSlotId = animchar_getSlotId(gun_attach__slot)


[es(on_appear)]
def gun_attach__altSlotId_init(evt : Event;
                               gun_attach__alternativeSlot : string;
                               var gun_attach__altSlotId : int&)
  gun_attach__altSlotId = animchar_getSlotId(gun_attach__alternativeSlot)


[es(on_appear, before=server_init_gun_es)]
def gun_attach__holsterSlotsIds_init(evt : Event;
                                     gun_attach__holsterSlots : Array?;
                                     var gun_attach__holsterSlotsIds : IntList)
  gun_attach__holsterSlotsIds |> resize(int(HUWeaponSlots EWS_NUM))
  var i = 0

  if gun_attach__holsterSlots != null
    let holsterSlotsCount = length(*gun_attach__holsterSlots)
    verify(holsterSlotsCount <= int(HUWeaponSlots EWS_NUM))

    while i < holsterSlotsCount
      let slotName = get_ecs_string((*gun_attach__holsterSlots)[i])
      gun_attach__holsterSlotsIds[i] = (slotName != null
                                          ? animchar_getSlotId(*slotName |> string())
                                          : -1)
      ++i

  while i < int(HUWeaponSlots EWS_NUM)
    gun_attach__holsterSlotsIds[i] = -1
    ++i


[es(REQUIRE=(animchar_render__enabled, gun__propsId),
    REQUIRE_NOT=skip_common_weap_phys_update)]
def human_gun_es(evt : CmdWeapPhysUpdate;
                 eid : EntityId;
                 gun__ammo : int;
                 gun__manuallyUnloaded : bool;
                 human_gun_attached : bool;
                 gun__isOverheat : bool = false;
                 gun : Gun)
  if !human_gun_attached
    return

  let ownerEid = evt.owner
  let atTime = evt.atTime
  let dt = evt.dt
  let isForReal = evt.isForReal
  let gctrl = evt.gctrl
  let gloc = evt.gloc
  let shoot = gctrl.shoot && !gun__isOverheat
  // TODO: move to separate server system
  human_gun_update_reload(gun, eid, gun__manuallyUnloaded, gctrl.shoot, isForReal, gun__ammo, ownerEid, (atTime - dt))

  let rndSeed = phys_time_to_seed(atTime)
  using() <| $(var gctr : GunControls#)
    gctr.shoot = shoot
    sendEventImmediate(eid, [[CmdGunUpdate atTime=atTime, isForReal=isForReal, seed=rndSeed, gctrl := gctr, gloc=gloc]])


[es(REQUIRE=(animchar_render__enabled, gun))]
def human_gun_parent_loaded_es(evt : EventOnParentLoaded;
                               human_gun_attached : bool;
                               var gun__animVarsGen : int&)
  if !human_gun_attached
    return

  ++gun__animVarsGen


[es(track=(human_weap__currentGunEid, human_weap__currentGunModEids), REQUIRE=human_weap__currentGunModEids)]
def human_gun_mods_changed_es(evt : Event;
                              human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=animchar_render__enabled)] (human_gun_attached : bool;
                                                                                var gun__animVarsGen : int&)
    if !human_gun_attached
      return

    ++gun__animVarsGen


[es(no_order, REQUIRE=animchar_render__enabled)]
def human_gun_attach_es(evt : CmdWeapAttach;
                        gun_attach__mainSlotId : int;
                        gun_attach__holsterSlotsIds : IntList?;
                        var human_gun_attached : bool&;
                        var slot_attach__slotId : int&;
                        var slot_attach__attachedTo : EntityId&;
                        var gun__visible : bool&)
  let ownerEid = evt.toEid
  if !ownerEid || !doesEntityExist(ownerEid)
    return

  let attachFlag = evt.isAttached
  let slotId = evt.slotId
  let weaponHolster = (gun_attach__holsterSlotsIds != null
                      ? ((*gun_attach__holsterSlotsIds)[slotId] >= 0)
                      : false)

  gun__visible = (attachFlag || weaponHolster)
  if attachFlag
    slot_attach__attachedTo = ownerEid
    slot_attach__slotId = gun_attach__mainSlotId
  elif weaponHolster
    slot_attach__attachedTo = ownerEid
    slot_attach__slotId = (*gun_attach__holsterSlotsIds)[slotId]
  else
    slot_attach__attachedTo = INVALID_ENTITY_ID
    slot_attach__slotId = -1

  human_gun_attached = attachFlag


[es(tag=render)]
def human_gun_detach_es(evt : CmdWeapDetach;
                        var animchar : AnimcharBaseComponent;
                        var ragdoll : PhysRagdoll;
                        var transform : float3x4)
  var rootTm = IDENT_TM
  animchar |> animchar_get_tm(rootTm)
  transform = rootTm

  if distance_sq(transform[3], get_hidden_pos()) > 1.0
    ragdoll |> ragdoll_startRagdoll(1, -1)
    animchar |> animchar_setPostController(ragdoll)


[es(tag=server, track=(human_weap__currentGunSlot, human_weap__gunEids))]
def human_gun_deflect_es(evt : Event;
                         human_weap__currentGunSlot : int;
                         human_weap__gunEids : EidList;
                         var human_weap__bulletDeflectionAngle : float&;
                         var human_weap__bulletDeflectionArmor : float&)
  let gun = human_weap__currentGunSlot >= 0 ? human_weap__gunEids[human_weap__currentGunSlot] : INVALID_ENTITY_ID
  query(gun) <| $ [es] (bulletDeflectAngle : float = 0.0;
                        bulletDeflectArmor : float = 0.0)
    human_weap__bulletDeflectionAngle = bulletDeflectAngle
    human_weap__bulletDeflectionArmor = bulletDeflectArmor


[es(tag=server, no_order)]
def human_gun_reset_reload_anim_es(evt : CmdWeapAttach;
                                   var gun__holsterGen : int&)
  let attachFlag = evt.isAttached
  if !attachFlag
    ++gun__holsterGen


def reset_reload_anim(gunAnim : GunAnim;
                      var physVars : PhysVars;
                      var animchar : AnimcharBaseComponent;
                      var animPhys : AnimatedPhys)
  physVars |> setVar(gunAnim.reloadVarId, -1.0)
  physVars |> setVar(gunAnim.singleReloadVarId, -1.0)
  animPhys |> anim_phys_update(animchar, physVars)
  animchar |> animchar_act(0.01, true)


[es(before=before_animchar_update_sync)]
def human_gun_reset_reload_anim_client_es(info : UpdateStageInfoAct;
                                          gun_anim : GunAnim;
                                          gun__holsterGen : int;
                                          var gun__prevHolsterGen : int&;
                                          var phys_vars : PhysVars;
                                          var animchar : AnimcharBaseComponent;
                                          var anim_phys : AnimatedPhys)
  if gun__holsterGen != gun__prevHolsterGen
    gun__prevHolsterGen = gun__holsterGen
    reset_reload_anim(gun_anim, phys_vars, animchar, anim_phys)


[es]
def human_gun_reset_reload_anim_on_vehicle_enter_client_es(evt : EventEnterVehicle;
                                                           gun_anim : GunAnim;
                                                           var phys_vars : PhysVars;
                                                           var animchar : AnimcharBaseComponent;
                                                           var anim_phys : AnimatedPhys)
  reset_reload_anim(gun_anim, phys_vars, animchar, anim_phys)


[es(tag=gameClient, before=before_animchar_update_sync, track=gun__animVarsGen, REQUIRE=gun__animVarsGen)]
def human_gun_anim_vars_es(info : Event;
                           gun__owner : EntityId;
                           gun__propsId : int)
  query(gun__owner) <| $ [es] (animchar : AnimcharBaseComponent;
                               human_weap__currentGunModEids : EidList;
                               hero : Tag?)
    gun_to_anim_get_props(gun__propsId) <| $(p : GunToAnimProps)
      assume ownerAnimVars = p.ownerAnimVars
      if ownerAnimVars.paramCount <= 0u
        return

      var animGraph = animchar.animGraph
      var animState = animchar.animState

      for pi in range(ownerAnimVars.paramCount)
        let paramType = ownerAnimVars |> datablock_getParamType(uint(pi))
        if paramType == int(DataBlockParamType TYPE_REAL)
          let paramName = ownerAnimVars |> datablock_getParamName(uint(pi))
          let paramId = *animGraph |> anim_graph_getParamId(paramName, int(PT_ScalarParam))
          if paramId >= 0
            *animState |> anim_state_holder_setParam(paramId, ownerAnimVars |> datablock_getReal(pi))
        elif paramType == int(DataBlockParamType TYPE_INT)
          let paramName = ownerAnimVars |> datablock_getParamName(uint(pi))
          let paramId = *animGraph |> anim_graph_getParamId(paramName,  int(PT_ScalarParamInt))
          if paramId >= 0
            *animState |> anim_state_holder_setParamInt(paramId, ownerAnimVars |> datablock_getInt(pi))

      if hero != null
        for gunModEid in human_weap__currentGunModEids
          query(gunModEid) <| $ [es] ([[shared_comp]] heroAnimVarsAddOffsets : Object)
            for param in heroAnimVarsAddOffsets
              var paramId = *animGraph |> anim_graph_getParamId(param.key, int(PT_ScalarParam))
              if paramId >= 0
                let val = *animState |> anim_state_holder_getParam(paramId)
                *animState |> anim_state_holder_setParam(paramId, val + (get_float(param.value) ?? 0.0))
              else
                paramId = *animGraph |> anim_graph_getParamId(param.key, int(PT_ScalarParamInt))
                if paramId >= 0
                  let val = *animState |> anim_state_holder_getParamInt(paramId)
                  *animState |> anim_state_holder_setParamInt(paramId, val + (get_int(param.value) ?? 0))


[es(tag=gameClient, no_order)]
def human_gun_update_firing_mode_es(info : UpdateStageInfoAct;
                                    gun : Gun;
                                    var gun__firingModeIndex : int&)
  gun__firingModeIndex = int(gun.firingModeIndex)


[es(tag=gameClient, on_appear, track=(gun__firingModeNames, gun__firingModeIndex))]
def human_gun_update_firing_mode_name_es(evt : Event;
                                         gun__firingModeNames : Array;
                                         gun__firingModeIndex : int;
                                         var gun__firingModeName : das_string)
  if gun__firingModeIndex >= 0
    gun__firingModeName := get_string(gun__firingModeNames[gun__firingModeIndex], "")
  else
    gun__firingModeName := ""


[es(tag=server, on_appear)]
def human_gun_init_offsets_es(evt : Event;
                              gun__propsId : int;
                              var gun__animOffset : float3&)
  gun_to_anim_get_props(gun__propsId) <| $(p : GunToAnimProps)
    assume ownerAnimVars = p.ownerAnimVars

    gun__animOffset.x =  ownerAnimVars |> datablock_getReal("gun_offset_along", 0.0)
    gun__animOffset.y =  ownerAnimVars |> datablock_getReal("gun_offset_up", 0.0)
    gun__animOffset.z = -ownerAnimVars |> datablock_getReal("gun_offset_across", 0.0)