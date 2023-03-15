require ecs
require math.base
require EnlistedHuman
require EnlistedHumanAnim
require PhysVars
require DagorRandom
require DagorMath
require DagorSystem
require EnlistedWeapon
require enlisted.events_enlisted

def set_phys_selected_weapon_var_from_props(var phys_vars : PhysVars;
                                            gunPropsId : int;
                                            gun_eid : EntityId;
                                            human_anim__selectedWeaponVarId : int;
                                            func_name : string)
  let result = gun_to_anim_get_props(gunPropsId) <| $(gunAnimProps : GunToAnimProps)
    phys_vars |> setVar(human_anim__selectedWeaponVarId, float(gunAnimProps.enumVarId))

  if !result
    query(gun_eid) <| $ [es] (gun__blk : string = "";
                              melee_weapon__blk : string = "")
      logerr("Can't get GunToAnimProps in {func_name} with id {gunPropsId} in gun__propsId,
             eid/template {gun_eid}<{getEntityTemplateName(gun_eid)}> gunBlk: {gun__blk} meleeBlk: {melee_weapon__blk}")


[es(REQUIRE_NOT=deadEntity)]
def human_anim_weap_es(info : ParallelUpdateFrameDelayed;
                       human_weap__gunEids : EidList;
                       human_weap__radioMode : bool = false;
                       animchar__visible : bool = true;
                       human_anim__selectedWeaponVarId : int;
                       human_net_phys : HumanActor;
                       var phys_vars : PhysVars)
  if human_weap__radioMode || !animchar__visible
    return

  let gunSlot = determine_current_weapon_slot(info.curTime, human_net_phys)
  if int(gunSlot) >= length(human_weap__gunEids)
    return

  assume phys = human_net_phys.phys
  query(human_weap__gunEids[int(gunSlot)]) <| $ [es(REQUIRE_NOT=grenade_thrower)] (gun__propsId : int)
    if gun__propsId >= 0 && human_anim__selectedWeaponVarId >= 0 && phys.canSwitchWeapon
      set_phys_selected_weapon_var_from_props(phys_vars, gun__propsId,
                                              human_weap__gunEids[int(gunSlot)],
                                              human_anim__selectedWeaponVarId, "human_anim_weap_es")

  query(human_weap__gunEids[int(gunSlot)]) <| $ [es(REQUIRE=grenade_thrower)] (grenade_thrower__selectedGrenadeVarId : int)
    if grenade_thrower__selectedGrenadeVarId >= 0 && human_anim__selectedWeaponVarId >= 0 && phys.canSwitchWeapon
      phys_vars |> setVar(human_anim__selectedWeaponVarId, float(grenade_thrower__selectedGrenadeVarId))


[es]
def human_anim_weap_attachment_es(info : ParallelUpdateFrameDelayed;
                                  human_attached_gun__attachedGunEid : EntityId;
                                  human_anim__selectedWeaponVarId : int;
                                  var phys_vars : PhysVars)
  if human_attached_gun__attachedGunEid == INVALID_ENTITY_ID
    return

  let gunPropsId = get_int(human_attached_gun__attachedGunEid, "gun__propsId") ?? -1
  if gunPropsId >= 0 && human_anim__selectedWeaponVarId != 0
    set_phys_selected_weapon_var_from_props(phys_vars, gunPropsId, human_attached_gun__attachedGunEid,
                                            human_anim__selectedWeaponVarId, "human_anim_weap_attachment_es")


[es(after=human_anim_weap_es)]
def human_anim_radio_es(info : ParallelUpdateFrameDelayed;
                        human_weap__radioEid : EntityId;
                        human_weap__radioMode : bool = false;
                        human_anim__selectedWeaponVarId : int;
                        var phys_vars : PhysVars)
  if !human_weap__radioMode
    return

  let gunPropsId = get_int(human_weap__radioEid, "gun__propsId") ?? -1
  if gunPropsId >= 0 && human_anim__selectedWeaponVarId != 0
    set_phys_selected_weapon_var_from_props(phys_vars, gunPropsId, human_weap__radioEid,
                                            human_anim__selectedWeaponVarId, "human_anim_radio_es")


[es(REQUIRE_NOT=deadEntity, REQUIRE=menuChar)]
def base_menu_animchar_set_weapon_selected(info : ParallelUpdateFrameDelayed;
                                           human_weap__gunEids : EidList;
                                           human_anim__selectedWeaponVarId : int;
                                           animchar__visible : bool = true;
                                           var phys_vars : PhysVars)
  if !animchar__visible || human_anim__selectedWeaponVarId < 0 || length(human_weap__gunEids) == 0
    return

  let gunEid = human_weap__gunEids[0] // currently all menu characters hold weapon in primary slot only

  query(gunEid) <| $ [es] (gun__propsId : int)
    if gun__propsId >= 0
      set_phys_selected_weapon_var_from_props(phys_vars, gun__propsId, gunEid,
                                              human_anim__selectedWeaponVarId, "base_menu_animchar_set_weapon_selected")
