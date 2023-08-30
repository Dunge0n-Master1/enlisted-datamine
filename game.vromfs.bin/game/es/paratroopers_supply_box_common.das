module paratroopers_supply_box_common shared
require ecs
require ecs.safe
require ecs.common

def push_valid(var list : StringList; val : string)
  if !empty(val)
    list |> push(val)

def private gather_preset_templates(preset : Object const?; var deps_list : StringList&)
  let soldiers = preset?.soldiers ?as Array
  if soldiers == null
    return
  for soldierObj in *soldiers
    let soldier = soldierObj as Object
    let weapTemplates = soldier?.human_weap__weapTemplates ?as Object
    if weapTemplates != null
      for it in *weapTemplates
        deps_list |> push_valid(it.value ?? "")
    let weapInfos = soldier?.human_weap__weapInfo ?as Array
    if weapInfos != null
      for it in *weapInfos
        let weapInfo = it as Object
        deps_list |> push_valid(weapInfo?.reserveAmmoTemplate ?? "")
        let additionalAmmoTemplates = weapInfo?.additionalReserveAmmoTemplates ?as Array
        if additionalAmmoTemplates != null
          for ammoTemplateItem in *additionalAmmoTemplates
            deps_list |> push_valid(ammoTemplateItem ?? "")

def private gather_supply_box_dependencies(squad : EntityId; var res : StringList)
  query(squad) <| $ [es] (squad__squadProfileId : string)
    query() <| $ [es] (paratroopers__supplySchemes : Object)
      var presets = paratroopers__supplySchemes[squad__squadProfileId] ?as Array
      if presets == null
        presets = paratroopers__supplySchemes.default ?as Array
      if presets == null
        return
      for it in *presets
        gather_preset_templates(it as Object, res)


def spawn_supply_box(template_name : string; pos : float3; squad : EntityId; velocity : float3; landing_pos : float2)
  createEntity(template_name) <| $(var init : ComponentsInitializer)
    var transform : float3x4
    identity(transform)
    transform[3] = pos
    init |> set("transform", transform)
    init |> set("supply_box__initVel", velocity)
    init |> set("supply_box__squad", squad)
    init |> set("human_parachute_wind__landingPoint", landing_pos)
    using() <| $(var deps : StringList)
      gather_supply_box_dependencies(squad, deps)
      init |> set("supply_box__template_deps_list", deps)
