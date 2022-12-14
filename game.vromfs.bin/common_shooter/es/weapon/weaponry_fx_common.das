module weaponry_fx_common shared

require ecs
require ecs.safe
require ecs.common
require math.base
require PhysMat
require DaWeapons
require debug.logerr_once
require DagorSystem
require BallisticsProps
require strings
require EnlistedDm


def logerr_debug(msg : string)
  if get_DAGOR_DBGLEVEL() > 0
    logerr(msg)


def calc_effect_tm(pos : float3; norm : float3)
  var tm = IDENT_TM
  tm[1] = normalize(norm)
  tm[2] = normalize(cross(float3(1, 0, 0), tm[1]))
  tm[0] = normalize(cross(tm[1], tm[2]))
  tm[3] = pos
  return tm


def get_fx_info_for_bullet_type(fx_info : Array; bullet_type_group_id : int) : Object const?
  for elem in fx_info
    let candidate = elem as Object
    if candidate == null
      logerr_once("get_fx_info_for_bullet_type: wrong type for element in fx_info; should be 'object'")
      continue
    let btGroupIds = get_ecs_IntList((*candidate).bulletTypeGroupIds)
    if btGroupIds == null
      //Either bulletTypeGroupIds is not an IntList (impossible, since it's created automatically)
      //or bulletTypeGroupIds doesn't exist (which means bulletTypeGroups was not specified)
      //We consider this case to be the same as if bulletTypeGroups existed and had ALL the bullet type groups
      return candidate
    if has_value(*btGroupIds, bullet_type_group_id)
      return candidate

  return null


def get_fx_for_mat(fx_info : Object; mat_id : int) : Object const?
  let matName = get_material_name(get_material(mat_id))
  return fx_info[matName] ?as Object


def get_value_for_closest_key(key : float; sorted_key_list : FloatList; info : Object)
  var closestKey = 0.0
  for keyFromList in sorted_key_list
    if key < keyFromList
      closestKey = keyFromList
      break
  return info[string(int(closestKey))] ?as Object


def get_global_bomb_fx_hit_info_for_impulse(impulse : float) : Object const?
  var ret : Object const?

  find_query() <| $ [es] (global_bomb_hit_fx__info : Object;
                          global_bomb_hit_fx__impulses : FloatList)
    ret = get_value_for_closest_key(impulse, global_bomb_hit_fx__impulses, global_bomb_hit_fx__info)
    return true

  if ret == null
    logerr("Can't find information in global_bomb_hit_fx__info: impulse {impulse} is too big")

  return ret


def get_global_bomb_fx_expl_info_for_expl_mass(expl_mass : float) : Object const?
  var ret : Object const?

  find_query() <| $ [es] (global_bomb_expl_fx__info : Object;
                          global_bomb_expl_fx__explMasses : FloatList)
    ret = get_value_for_closest_key(expl_mass, global_bomb_expl_fx__explMasses, global_bomb_expl_fx__info)
    return true

  if ret == null
    logerr("Can't find information in global_bomb_expl_fx__info: explosive mass {expl_mass} is too big")

  return ret


def get_bomb_fx_info(launch_desc : LaunchDesc; exploded : bool; vel : float3)
  var fxInfo : Object const?

  if exploded
    let explMass = explosive_get_props(int(launch_desc.shellId.damageId))?.mass ?? 0.0
    fxInfo = get_global_bomb_fx_expl_info_for_expl_mass(explMass)
  else
    var mass : float
    projectile_get_props(int(launch_desc.shellId.shellId)) <| $(ballisticsProps : ProjectileProps)
      mass = ballisticsProps.mass
    let impulse = mass * length(vel)
    fxInfo = get_global_bomb_fx_hit_info_for_impulse(impulse)

  return fxInfo


def get_bomb_fx_name(fx_info : Object;
                     is_under_water : bool;
                     mat_id : int) : das_string const?
  let fxInfoForMaterials = fx_info.info ?as Object
  if fxInfoForMaterials == null
    logerr_once("get_bomb_fx_name: Can't find 'info:Object' in fx_info")
  let fxByMat = (fxInfoForMaterials == null ? null : get_fx_for_mat(*fxInfoForMaterials, is_under_water ? get_material_id("water3d") : mat_id))
  return (fxByMat == null ? fx_info.defaultFx : fxByMat?.fx) ?as string


def private get_fx_name(fx_info : Object; fx_list_element : string; def_fx_element : string; mat_id : int)
  var fxName : string

  let fxs = get_ecs_StringList(fx_info[fx_list_element])
  if fxs != null
    fxName = string((*fxs)[mat_id])

  if empty(fxName)
    let defaultFx = fx_info[def_fx_element] ?as string
    if defaultFx == null
      logerr_once("get_fx_name: can't find '{def_fx_element}:t' in fx_info")
      return ""
    fxName = string(*defaultFx)

  return fxName


def get_firearm_fx_name(effect_group_name : string;
                        mat_id : int;
                        bullet_type_id : int;
                        should_stop : bool;
                        ricochet : bool)
  var fxName = ""

  find_query() <| $ [es] (global_hit_fx__effectGroups : Object;
                          global_hit_fx__bulletTypeIdToGroupIdMap : IntList)
    let fxInfo = global_hit_fx__effectGroups[effect_group_name] ?as Array
    if fxInfo == null
      return true

    let btgId = bullet_type_id < 0 ? -1 : global_hit_fx__bulletTypeIdToGroupIdMap[bullet_type_id]
    let fxInfoForBt = get_fx_info_for_bullet_type(*fxInfo, btgId)
    if fxInfoForBt == null
      logerr_debug("get_firearm_fx_name: couldn't find fx info for bullet type id {bullet_type_id}. ")
      return true

    if ricochet
      fxName = get_fx_name(*fxInfoForBt, "ricochetFxs", "defaultRicochetFx", mat_id)
    elif should_stop
      fxName = get_fx_name(*fxInfoForBt, "fxs", "defaultFx", mat_id)
    else
      fxName = get_fx_name(*fxInfoForBt, "penetrationFxs", "defaultPenetrationFx", mat_id)

    return true

  return fxName


def get_projectile_fx_name(effect_group_name : string;
                           is_bomb : bool;
                           launch_desc : LaunchDesc;
                           mat_id : int;
                           bullet_type_id : int;
                           is_under_water : bool;
                           exploded : bool = true;
                           vel : float3 = float3(0.0, 0.0, 0.0);
                           should_stop : bool = true;
                           ricochet : bool = false)
  let matIdAdjusted = mat_id < 0 ? 0 : mat_id
  if is_bomb && bullet_type_id < 0
    let fxInfo = get_bomb_fx_info(launch_desc, exploded, vel)
    if fxInfo == null
      return ""
    return get_bomb_fx_name(*fxInfo, is_under_water, matIdAdjusted) ?? ""

  if should_stop && exploded && is_under_water
    return ""

  return get_firearm_fx_name(effect_group_name, matIdAdjusted, bullet_type_id, should_stop, ricochet)
