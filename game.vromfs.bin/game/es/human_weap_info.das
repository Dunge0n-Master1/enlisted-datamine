require ecs
require ecs.safe
require HumanPhys
require ecs.common
require DagorSystem


def init_ammo_item(ammo_template : string; var weap_info : Object?)
  let templatePtr = ammo_template |> getTemplateByName
  if templatePtr == null
    logerr("Gun holder template {ammo_template} doesn't have exist")
    return

  let itemProto = *templatePtr |> getTemplateComponent("item__proto") |> get_ecs_string
  if itemProto == null
    logerr("Gun holder {itemProto} doesn't have item.proto")
    return

  let itemId = *itemProto |> string() |> ecs_hash |> int()
  *weap_info |> set("itemId", itemId)


[es(on_appear, tag=server)]
def human_init_weap_info_es(evt : Event; var human_weap__weapInfo : ecs::Array&)
  for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
    var weapInfo = human_weap__weapInfo[int(slotId)] |> getRW_ecs_object
    let ammoTemplate = get_string(weapInfo, "reserveAmmoTemplate", "")
    if ammoTemplate != ""
      init_ammo_item(ammoTemplate, weapInfo)

    let additionalAmmoTemplates = get_ecs_array(weapInfo, "additionalReserveAmmoTemplates")
    if additionalAmmoTemplates != null
      for ammoTemplateItem in *additionalAmmoTemplates
        init_ammo_item(ammoTemplateItem ?? "", weapInfo)
