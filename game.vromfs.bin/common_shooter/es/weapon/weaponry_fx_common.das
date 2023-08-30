module weaponry_fx_common shared

require ecs
require ecs.safe
require ecs.common
require math.base
require PhysMat
require DaWeapons
require DagorSystem
require BallisticsProps
require Ballistics
require DngDm
require daslib/algorithm


enum EffectPresetKeyTypes
  BulletType
  Caliber
  Impulse
  ExplMass


def calc_effect_tm(pos : float3; norm : float3)
  var tm = IDENT_TM
  tm[1] = normalize(norm)
  tm[2] = normalize(cross(float3(1, 0, 0), tm[1]))
  tm[0] = normalize(cross(tm[1], tm[2]))
  tm[3] = pos
  return tm


def private get_fx_name(fx_info : Object; fx_list_element : string; def_fx_element : string; mat_id : int)
  var fxName : string

  let fxs = get_ecs_StringList(fx_info[fx_list_element])
  if fxs != null
    fxName = string((*fxs)[mat_id])

  if empty(fxName)
    fxName = fx_info[def_fx_element] ?? ""

  return fxName


def private get_fx_name_from_effect_group(effect_group : Object;
                                          mat_id : int;
                                          should_stop : bool;
                                          ricochet : bool)
  if ricochet
    return get_fx_name(effect_group, "ricochetFxs", "defaultRicochetFx", mat_id)
  elif should_stop
    return get_fx_name(effect_group, "fxs", "defaultFx", mat_id)
  else
    return get_fx_name(effect_group, "penetrationFxs", "defaultPenetrationFx", mat_id)


def private get_index_in_effect_preset(preset : Object;
                                       launch_desc : LaunchDesc;
                                       dm_projectile_state : ProjectileState;
                                       projectile_ballistics : ProjectileBallistics;
                                       value_count : int)
  var index = -1

  let keyTypeId = preset.keyTypeId ?as int
  if keyTypeId == null
    return index

  var keyCount = 0

  if *keyTypeId == int(EffectPresetKeyTypes BulletType)
    let keys = get_ecs_IntList(preset.keys)
    keyCount = (keys == null ? 0 : length(*keys))
    if keyCount != value_count
      return index

    if keys != null
      let bulletTypeId = dm_projectile_state.projectileTypePropsId
      find_query() <| $ [es] (global_hit_fx__bulletTypeIdToGroupIdMap : IntList)
        let bulletTypeGroupId = bulletTypeId < 0 ? -1 : global_hit_fx__bulletTypeIdToGroupIdMap[bulletTypeId]
        index = find_index(*keys, bulletTypeGroupId)
        return true
  else
    let keys = get_ecs_FloatList(preset.keys)
    keyCount = (keys == null ? 0 : length(*keys))
    if keyCount != value_count
      return index

    if keys != null
      var key = 0.0
      if *keyTypeId == int(EffectPresetKeyTypes Caliber)
        projectile_get_props(int(launch_desc.shellId.shellId)) <| $(ballisticsProps : ProjectileProps)
          let M_TO_MM = 1000.0
          key = M_TO_MM * ballisticsProps.caliber
      elif *keyTypeId == int(EffectPresetKeyTypes Impulse)
        projectile_get_props(int(launch_desc.shellId.shellId)) <| $(ballisticsProps : ProjectileProps)
          let mass = ballisticsProps.mass
          let vel = projectile_ballistics.state.vel
          key = mass * length(vel)
      elif *keyTypeId == int(EffectPresetKeyTypes ExplMass)
        key = explosive_get_props(int(launch_desc.shellId.damageId))?.mass ?? 0.0
      else
        //unsupported key type
        return index
      index = lower_bound(*keys, key)

  if index >= keyCount
    index = -1
  return index

def private get_effect_group_id_from_preset(effect_preset : Object;
                                            effect_presets : Array;
                                            launch_desc : LaunchDesc;
                                            dm_projectile_state : ProjectileState;
                                            projectile_ballistics : ProjectileBallistics)
  var effectGroupId = -1

  let values = effect_preset.values ?as Array
  let valueCount = (values == null ? 0 : length(*values))
  let index = get_index_in_effect_preset(effect_preset, launch_desc, dm_projectile_state, projectile_ballistics, valueCount)

  let valueChildComp = index >= 0 ? (*values)?[index] : effect_preset.defaultValue
  if valueChildComp == null
    return effectGroupId
  let valueInt = *valueChildComp as int

  //See descriptions of cases in parse_effect_preset_values
  //Case 1
  if valueInt == null
    let nextEffectPreset = *valueChildComp as Object
    if nextEffectPreset == null
      return effectGroupId
    effectGroupId = get_effect_group_id_from_preset(*nextEffectPreset, effect_presets, launch_desc, dm_projectile_state, projectile_ballistics)
  //Case 2
  elif *valueInt < 0
    let nextEffectPresetId = -(*valueInt) - 1
    let nextEffectPreset = effect_presets[nextEffectPresetId] as Object
    if nextEffectPreset == null
      return effectGroupId
    effectGroupId = get_effect_group_id_from_preset(*nextEffectPreset, effect_presets, launch_desc, dm_projectile_state, projectile_ballistics)
  //Case 3
  else
    effectGroupId = *valueInt - 1
  return effectGroupId


def get_projectile_fx_name(hit_effect_descriptor : int;
                           expl_effect_descriptor : int;
                           launch_desc : LaunchDesc;
                           dm_projectile_state : ProjectileState;
                           projectile_ballistics : ProjectileBallistics;
                           mat_id : int;
                           is_under_water : bool;
                           exploded : bool = true;
                           should_stop : bool = true;
                           ricochet : bool = false)
  var effectGroup : Object const?

  find_query() <| $ [es] (global_hit_fx__effectGroups : Array; global_hit_fx__effectPresets : Array)
    var effectGroupId = -1
    var effectPresetId = -1

    if exploded
      if expl_effect_descriptor > 0
        effectGroupId = expl_effect_descriptor - 1
      elif expl_effect_descriptor < 0
        effectPresetId = -expl_effect_descriptor - 1
      elif hit_effect_descriptor > 0
        effectGroupId = hit_effect_descriptor - 1
      elif hit_effect_descriptor < 0
        effectPresetId = -hit_effect_descriptor - 1
    else
      if hit_effect_descriptor > 0
        effectGroupId = hit_effect_descriptor - 1
      elif hit_effect_descriptor < 0
        effectPresetId = -hit_effect_descriptor - 1

    if effectPresetId >= 0
      let effectPreset = global_hit_fx__effectPresets[effectPresetId] as Object
      if effectPreset == null
        return true
      effectGroupId = get_effect_group_id_from_preset(*effectPreset, global_hit_fx__effectPresets,
        launch_desc, dm_projectile_state, projectile_ballistics)

    if effectGroupId >= 0
      effectGroup = global_hit_fx__effectGroups[effectGroupId] as Object
    return true

  if effectGroup == null
    return ""

  if is_under_water && should_stop
    if !exploded
      return ""
    let waterSplashOnExplosion = (*effectGroup).waterSplashOnExplosion ?? false
    if !waterSplashOnExplosion
      return ""

  let matIdAdjusted = (is_under_water ? get_material_id("water3d") :
                       mat_id >= 0 ? mat_id : 0)

  return get_fx_name_from_effect_group(*effectGroup, matIdAdjusted, should_stop, ricochet)
