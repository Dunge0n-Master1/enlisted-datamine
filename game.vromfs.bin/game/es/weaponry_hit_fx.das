require ecs
require ecs.safe
require PhysMat
require DagorSystem
require common_shooter.es.weapon.weaponry_fx_common
require strings
require EnlistedDm


[es(on_appear)]
def global_bomb_hit_fx_info_init_es(evt : Event;
                                    var global_bomb_hit_fx__info : Object&;
                                    var global_bomb_hit_fx__impulses : FloatList&)
  var impulses : array<float>

  for elem in global_bomb_hit_fx__info
    let impulse = to_float(elem.key)
    if impulse <= 0.0
      logerr("Incorrect value for impulse found in global_bomb_hit_fx__info: {elem.key}")
      continue
    push(impulses, impulse)

  sort(impulses)
  for impulse in impulses
    push(global_bomb_hit_fx__impulses, impulse)

[es(on_appear)]
def global_bomb_expl_fx_info_init_es(evt : Event;
                                     var global_bomb_expl_fx__info : Object&;
                                     var global_bomb_expl_fx__explMasses : FloatList&)
  var explMasses : array<float>

  for elem in global_bomb_expl_fx__info
    let explMass = to_float(elem.key)
    if explMass <= 0.0
      logerr("Incorrect value for explMass found in global_bomb_expl_fx__info: {elem.key}")
      continue
    push(explMasses, explMass)

  sort(explMasses)
  for explMass in explMasses
    push(global_bomb_expl_fx__explMasses, explMass)

def get_bullet_type_group_id(bullet_type_group : string; bullet_type_group_name_to_id_map : Object)
  var id = -1
  find_query() <| $ [es] (global_hit_fx__bulletTypeGroups : Object)
    for elem in global_hit_fx__bulletTypeGroups
      if bullet_type_group == elem.key
        id = bullet_type_group_name_to_id_map[elem.key] ?? -1
        break
    return true
  return id

def parse_fx_info_for_material(pmid : int;
                               info_for_material : Object;
                               var fxs : StringList#&;
                               var penetrationFxs : StringList#&;
                               var ricochetFxs : StringList#&)
  fxs[pmid] := info_for_material.fx ?? ""
  penetrationFxs[pmid] := info_for_material.penetrationFx ?? ""
  ricochetFxs[pmid] := info_for_material.ricochetFx ?? ""

def parse_fx_info_for_materials(pmid_count : int; material_groups : Object; var fx_info : Object&)
  let infoForMats = fx_info.info ?as Object
  if infoForMats == null
    return

  using() <| $(var fxs : StringList#)
    using() <| $(var penetrationFxs : StringList#)
      using() <| $(var ricochetFxs : StringList#)
        resize(fxs, pmid_count)
        resize(penetrationFxs, pmid_count)
        resize(ricochetFxs, pmid_count)

        let groupPrefix = "group__"
        let groupPrefixLen = length(groupPrefix)

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
              if !empty(fxs[pmid]) || !empty(penetrationFxs[pmid]) || !empty(ricochetFxs[pmid])
                continue
              parse_fx_info_for_material(pmid, *obj, fxs, penetrationFxs, ricochetFxs)
          else                                  //if key does not start with groupPrefix, we're dealing with a single material
            let pmid = get_material_id(elem.key)
            if pmid <= 0
              continue
            //Set the effects for this pmid (or change them, if they were already set as part of material group)
            //In other words, settings for a single material have higher priority than settings for material groups
            parse_fx_info_for_material(pmid, *obj, fxs, penetrationFxs, ricochetFxs)
        fx_info |> set("fxs", fxs)
        fx_info |> set("penetrationFxs", penetrationFxs)
        fx_info |> set("ricochetFxs", ricochetFxs)

def parse_effect_group(pmid_count : int; material_groups : Object; bullet_type_group_name_to_id_map : Object; var effect_group : Array&)
  for elem in effect_group
    var info = elem as Object
    if info == null
      logerr("parse_effect_group: wrong type for element in effect_group; should be 'object'")
      continue
    parse_fx_info_for_materials(pmid_count, material_groups, *info)
    let btGroups = get_ecs_StringList((*info).bulletTypeGroups)
    if btGroups == null
      //bulletTypeGroups has wrong type or doesn't exist. Either way,
      //we don't consider this to be an error and we don't create bulletTypeGroupIds
      //(see comments in get_fx_info_for_bullet_type)
      continue
    using() <| $(var btGroupIds : IntList#)
      for btGroup in *btGroups
        let btgId = get_bullet_type_group_id(string(btGroup), bullet_type_group_name_to_id_map)
        if btgId < 0
          logerr("parse_effect_group: bullet type group {btGroup} does not exist")
          continue
        push(btGroupIds, btgId)
      *info |> set("bulletTypeGroupIds", btGroupIds)

[es(on_appear)]
def gun_hit_fx_init_es(evt : Event;
                       var gun_hit_fx__info : Array&)
  let pmidCount = physMatCount()

  find_query() <| $ [es] (global_hit_fx__materialGroups : Object; global_hit_fx__bulletTypeGroupNameToIdMap : Object)
    parse_effect_group(pmidCount, global_hit_fx__materialGroups, global_hit_fx__bulletTypeGroupNameToIdMap, gun_hit_fx__info)
    return true

[es(on_appear)]
def global_hit_fx_init_es(evt : Event;
                          global_hit_fx__materialGroups : Object;
                          global_hit_fx__bulletTypeGroups : Object;
                          var global_hit_fx__bulletTypeGroupNameToIdMap : Object&;
                          var global_hit_fx__bulletTypeIdToGroupIdMap : IntList&;
                          var global_hit_fx__effectGroups : Object&)
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
    var effectGroup = elem.value as Array
    if effectGroup == null
      logerr("global_hit_fx_init_es: wrong value type for '{elem.key}' in global_hit_fx__effectGroups; should be 'array'")
      continue
    parse_effect_group(pmidCount, global_hit_fx__materialGroups, global_hit_fx__bulletTypeGroupNameToIdMap, *effectGroup)
