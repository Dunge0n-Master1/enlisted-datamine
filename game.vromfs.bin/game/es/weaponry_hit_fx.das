require ecs
require ecs.safe
require ecs.extra_set
require PhysMat
require DagorSystem
require common_shooter.es.weapon.weaponry_fx_common
require strings
require EnlistedDm

def get_fx_name(field_name : string; info_for_material : Object)
  let fxName = info_for_material[field_name] ?as string
  if fxName == null
    return ""
  elif empty(*fxName)
    return "-"
  else
    return string(*fxName)

def parse_fx_info_for_material(pmid : int;
                               info_for_material : Object;
                               var fxs, penetrationFxs, ricochetFxs : array<string>)
  fxs[pmid] := get_fx_name("fx", info_for_material)
  penetrationFxs[pmid] := get_fx_name("penetrationFx", info_for_material)
  ricochetFxs[pmid] := get_fx_name("ricochetFx", info_for_material)

def parse_effect_group(pmid_count : int; material_groups : Object; var effect_group : Object&)
  let infoForMats = effect_group.info ?as Object
  if infoForMats == null
    return

  var fxs, penetrationFxs, ricochetFxs : array<string>

  resize(fxs, pmid_count)
  resize(penetrationFxs, pmid_count)
  resize(ricochetFxs, pmid_count)

  let groupPrefix = "group__"
  let groupPrefixLen = length(groupPrefix)
  var pmidSet : array<bool>
  resize(pmidSet, pmid_count)

  for elem in *infoForMats
    let obj = elem.value as Object
    if obj == null
      logerr("parse_fx_info_for_materials: wrong value type for material {elem.key} in fx_info; should be 'object'")
      continue

    if starts_with(elem.key, groupPrefix) //if key starts with groupPrefix, we're dealing with a material group
      let matGroupName = slice(elem.key, groupPrefixLen)
      let matGroup = get_ecs_StringList(material_groups[matGroupName])
      if matGroup == null
        logerr("parse_fx_info_for_materials: failed to find material group '{matGroupName}'")
        continue
      for matName in *matGroup
        let pmid = get_material_id(string(matName))
        if pmid <= 0
          continue
        //If effects were already set for this pmid, then we don't change them
        if pmidSet[pmid]
          continue
        parse_fx_info_for_material(pmid, *obj, fxs, penetrationFxs, ricochetFxs)
        pmidSet[pmid] = true
    else                                  //if key does not start with groupPrefix, we're dealing with a single material
      let pmid = get_material_id(elem.key)
      if pmid <= 0
        continue
      //Set the effects for this pmid (or change them, if they were already set as part of material group)
      //In other words, settings for a single material have higher priority than settings for material groups
      parse_fx_info_for_material(pmid, *obj, fxs, penetrationFxs, ricochetFxs)
      pmidSet[pmid] = true
  effect_group |> set("fxs", fxs)
  effect_group |> set("penetrationFxs", penetrationFxs)
  effect_group |> set("ricochetFxs", ricochetFxs)

def parse_effect_preset_values(effect_groups : Array; effect_presets : Array; var value : ChildComponent&)
  //value is either:
  //Case 1. an object, describing next-level effect preset (subpreset); in this case, call parse_effect_preset (recursion)
  //Case 2. a string that starts with presetPrefix; in this case, the part after the prefix is a name of some top level effect preset
  //Case 3. a string that doesn't start with presetPrefix; in this case, it's an effect group name.
  //In cases 2 and 3 we need to replace value with an integer value (for speed). For an effect group,
  //we use (id + 1), where id is effect group's id (index). For an effect preset, we use -(id + 1) where is effect preset's id.
  //This way, we can tell apart groups and presets: if the number is positive, it's a group; if the number is negative, it's a preset;
  //otherwise, it's not defined.
  let presetPrefix = "preset:"
  let presetPrefixLen = length(presetPrefix)

  let valueString = value as string

  //Case 1
  if valueString == null
    var subEffectPreset = value as Object
    if subEffectPreset == null
      logerr("parse_effect_preset_values: found a value that is neither 't' nor 'object'")
      return
    parse_effect_preset(effect_groups, effect_presets, *subEffectPreset)
  //Case 2
  elif starts_with(string(*valueString), presetPrefix)
    let presetName = slice(string(*valueString), presetPrefixLen)
    let presetId = get_id_from_name(effect_presets, presetName)
    if presetId < 0
      logerr("parse_effect_preset_values: found a reference to a non-existent effect preset '{presetName}'")
      return
    using() <| $(var newValue : ChildComponent)
      set(newValue, -(presetId + 1))
      value := newValue
  //Case 3
  else
    let groupId = get_id_from_name(effect_groups, string(*valueString))
    if groupId < 0
      logerr("parse_effect_preset_values: found a reference to a non-existent effect group '{*valueString}'")
      return
    using() <| $(var newValue : ChildComponent)
      set(newValue, groupId + 1)
      value := newValue

def parse_effect_preset(effect_groups : Array; effect_presets : Array; var effect_preset : Object&)
  let keyType = effect_preset.keyType ?as string
  if keyType == null
    logerr("parse_effect_preset: effect preset {effect_preset.name ?? ""} doesn't have element 'keyType:t'")
    return

  var values = effect_preset.values ?as Array
  let valueCount = (values == null ? 0 : length(*values))
  var keyCount = 0

  if *keyType == "bullet_type"
    effect_preset |> set("keyTypeId", int(EffectPresetKeyTypes BulletType))

    let keys = get_ecs_StringList(effect_preset.keys)
    keyCount = (keys == null ? 0 : length(*keys))

    if keys != null
      var newKeys : array<int>
      find_query() <| $ [es] (global_hit_fx__bulletTypeGroupNameToIdMap : Object)
        for bulletTypeGroupName in *keys
          let bulletTypeGroupId = global_hit_fx__bulletTypeGroupNameToIdMap[string(bulletTypeGroupName)] ?as int
          if bulletTypeGroupId == null
            logerr("parse_effect_preset: effect preset {effect_preset.name ?? ""} references a non-existent bullet type group {bulletTypeGroupName}")
            return true
          newKeys |> push(*bulletTypeGroupId)
        effect_preset |> erase("keys")
        effect_preset |> set("keys", newKeys)
        return true
  else
    if *keyType == "caliber"
      effect_preset |> set("keyTypeId", int(EffectPresetKeyTypes Caliber))
    elif *keyType == "impulse"
      effect_preset |> set("keyTypeId", int(EffectPresetKeyTypes Impulse))
    elif *keyType == "expl_mass"
      effect_preset |> set("keyTypeId", int(EffectPresetKeyTypes ExplMass))
    else
      logerr("parse_effect_preset: effect preset has unsupported keyType")
      return

    let keys = get_ecs_FloatList(effect_preset.keys)
    keyCount = (keys == null ? 0 : length(*keys))

  if keyCount != valueCount
    logerr("parse_effect_preset: effect preset {effect_preset.name ?? ""} has keys and values with different sizes")
    return

  if valueCount > 0
    for elem in *values
      parse_effect_preset_values(effect_groups, effect_presets, elem)

  var defaultValue = effect_preset.defaultValue
  if defaultValue == null
    logerr("parse_effect_preset: effect preset {effect_preset.name ?? ""} does not have defaultValue")
    return
  parse_effect_preset_values(effect_groups, effect_presets, *defaultValue)

def get_id_from_name(arr : Array; name : string)
  for id, elem in iter_range(arr), arr
    let curName = (elem as Object)?.name ?as string
    if curName == null
      return -1
    if name == *curName
      return id
  return -1

[es(on_appear)]
def gun_hit_fx_hit_init_es(evt : Event;
                           gun_hit_fx__hitEffectGroupName : das_string const?;
                           gun_hit_fx__hitEffectPresetName : das_string const?;
                           var gun_hit_fx__hitEffectDescriptor : int&)
  find_query() <| $ [es] (global_hit_fx__effectGroups : Array; global_hit_fx__effectPresets : Array)
    if gun_hit_fx__hitEffectGroupName != null
      let id = get_id_from_name(global_hit_fx__effectGroups, string(*gun_hit_fx__hitEffectGroupName))
      if id < 0
        logerr("gun_hit_fx_hit_init_es: failed to find '{*gun_hit_fx__hitEffectGroupName}' in global_hit_fx__effectGroups")
        return true
      gun_hit_fx__hitEffectDescriptor = id + 1
    elif gun_hit_fx__hitEffectPresetName != null
      let id = get_id_from_name(global_hit_fx__effectPresets, string(*gun_hit_fx__hitEffectPresetName))
      if id < 0
        logerr("gun_hit_fx_hit_init_es: failed to find '{*gun_hit_fx__hitEffectPresetName}' in global_hit_fx__effectPresets")
        return true
      gun_hit_fx__hitEffectDescriptor = -(id + 1)
    return true

[es(on_appear)]
def gun_hit_fx_expl_init_es(evt : Event;
                            gun_hit_fx__explEffectGroupName : das_string const?;
                            gun_hit_fx__explEffectPresetName : das_string const?;
                            var gun_hit_fx__explEffectDescriptor : int&)
  find_query() <| $ [es] (global_hit_fx__effectGroups : Array; global_hit_fx__effectPresets : Array)
    if gun_hit_fx__explEffectGroupName != null
      let id = get_id_from_name(global_hit_fx__effectGroups, string(*gun_hit_fx__explEffectGroupName))
      if id < 0
        logerr("gun_hit_fx_expl_init_es: failed to find '{*gun_hit_fx__explEffectGroupName}' in global_hit_fx__effectGroups")
        return true
      gun_hit_fx__explEffectDescriptor = id + 1
    elif gun_hit_fx__explEffectPresetName != null
      let id = get_id_from_name(global_hit_fx__effectPresets, string(*gun_hit_fx__explEffectPresetName))
      if id < 0
        logerr("gun_hit_fx_expl_init_es: failed to find '{*gun_hit_fx__explEffectPresetName}' in global_hit_fx__effectPresets")
        return true
      gun_hit_fx__explEffectDescriptor = -(id + 1)
    return true

[es(on_appear)]
def global_hit_fx_init_es(evt : Event;
                          global_hit_fx__materialGroups : Object;
                          global_hit_fx__bulletTypeGroups : Object;
                          var global_hit_fx__bulletTypeGroupNameToIdMap : Object&;
                          var global_hit_fx__bulletTypeIdToGroupIdMap : IntList&;
                          var global_hit_fx__effectGroups : Array&;
                          var global_hit_fx__effectPresets : Array&)
  let pmidCount = physMatCount()

  for _i in range(getBulletTypePropCount(get_damage_model_params()))
    push(global_hit_fx__bulletTypeIdToGroupIdMap, -1)

  var btgCount = 0

  for elem in global_hit_fx__bulletTypeGroups
    let btgName = elem.key
    global_hit_fx__bulletTypeGroupNameToIdMap |> set(btgName, btgCount)
    btgCount += 1

  for btGroupId, elem in iter_range(global_hit_fx__bulletTypeGroups), global_hit_fx__bulletTypeGroups
    let bulletTypes = get_ecs_StringList(elem.value)

    if bulletTypes == null
      logerr("global_hit_fx_init_es: wrong value type for '{elem.key}' in global_hit_fx__bulletTypeGroups; should be 'list<t>'")
      continue

    for bulletType in *bulletTypes
      let btId = getBulletTypeId(get_damage_model_params(), string(bulletType))
      if btId >= 0
        global_hit_fx__bulletTypeIdToGroupIdMap[btId] = btGroupId

  for elem in global_hit_fx__effectGroups
    var effectGroup = elem as Object
    if effectGroup == null
      logerr("global_hit_fx_init_es: all elements in global_hit_fx__effectGroups should be 'object'")
      continue
    parse_effect_group(pmidCount, global_hit_fx__materialGroups, *effectGroup)

  for elem in global_hit_fx__effectPresets
    var effectPreset = elem as Object
    if effectPreset == null
      logerr("global_hit_fx_init_es: all elements in global_hit_fx__effectPresets should be 'object'")
      continue
    parse_effect_preset(global_hit_fx__effectGroups, global_hit_fx__effectPresets, *effectPreset)
