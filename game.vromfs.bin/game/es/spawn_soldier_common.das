module spawn_soldier_common shared

require ecs
require ecs.safe
require DagorSystem

def private gather_dependent_templates(baseTemplate : ecs::Template;
                                       soldierComponents : Object const?;
                                       depcb : block<(ptname : das_string const?) : void>)
  // Components from the baseTemplate are used, if there are no soldierComponents to overwrite them
  var weapTemplatesPtr = get_ecs_object(soldierComponents, "human_weap__weapTemplates")
  if weapTemplatesPtr == null
    weapTemplatesPtr = getTemplateComponent(baseTemplate, "human_weap__weapTemplates") ?as Object
  if weapTemplatesPtr != null
    for kv in *weapTemplatesPtr
      depcb |> invoke(get_ecs_string(kv.value))

  var weapInfoPtr = get_ecs_array(soldierComponents, "human_weap__weapInfo")
  if weapInfoPtr == null
    weapInfoPtr = getTemplateComponent(baseTemplate, "human_weap__weapInfo") ?as Array
  if weapInfoPtr != null
    for weapInfoSlot in *weapInfoPtr
      let weapInfoSlotObj = weapInfoSlot as Object

      depcb |> invoke(weapInfoSlotObj |> get_ecs_string("reserveAmmoTemplate"))

      let additionalAmmoTemplates = weapInfoSlotObj?.additionalReserveAmmoTemplates ?as Array
      if additionalAmmoTemplates != null
        for ammoTemplateItem in *additionalAmmoTemplates
          depcb |> invoke(ammoTemplateItem as string)

  var itemRemapPtr = get_ecs_object(soldierComponents, "human_weap__itemRemap")
  if itemRemapPtr == null
    itemRemapPtr = getTemplateComponent(baseTemplate, "human_weap__itemRemap") ?as Object
  if itemRemapPtr != null
    for kv in *itemRemapPtr
      depcb |> invoke(get_ecs_string(kv.value))

// Fill the list of templates to instantiate, so we can safely call createInstantiatedEntitySync later for them
def init_soldier_tpl_deps(baseTemplate : ecs::Template;
                          var initOut : ComponentsInitializer;
                          soldierComponents : Object const? = null)
  let depsCompKey = "human_weap__template_deps_list"
  let depsCompHash = ecs_hash(depsCompKey)
  if !templateHasComponent(baseTemplate, depsCompKey, depsCompHash)
    return false

  using() <| $(var depsList : StringList)
    // First copy manually specified dependencies, so they don't get overwritten
    let baseDepsPtr = get_ecs_StringList(getTemplateComponent(baseTemplate, "human_weap__template_deps_list"))
    if baseDepsPtr != null
      for ptname in *baseDepsPtr
        if ptname != ""
          depsList |> push(ptname)
        else
          logerr("Unexpected empty template in human_weap__template_deps_list")

    gather_dependent_templates(baseTemplate, soldierComponents) <| $(ptname : das_string const?) : void
      if ptname != null && *ptname != ""
        depsList |> push(*ptname)
    set(initOut, depsCompKey, depsCompHash, depsList)
  return true
