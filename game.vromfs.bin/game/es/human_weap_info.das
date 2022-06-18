require ecs
require HumanPhys
require ecs.common
require DagorSystem

[es(on_appear, tag=server)]
def human_init_weap_info_es(evt : Event; var human_weap__weapInfo : ecs::Array&)
  for slotId in [[HUWeaponSlots HUWeaponSlots EWS_PRIMARY; HUWeaponSlots EWS_SECONDARY; HUWeaponSlots EWS_TERTIARY]]
    var weapInfo = human_weap__weapInfo[int(slotId)] |> getRW_ecs_object
    let ammoTemplate = get_string(weapInfo, "reserveAmmoTemplate", "")
    if ammoTemplate == ""
      continue

    let templatePtr = ammoTemplate |> getTemplateByName
    if templatePtr == null
      logerr("Gun holder template {ammoTemplate} doesn't have exist")
      continue
    let itemProto = *templatePtr |> getTemplateComponent("item__proto") |> get_ecs_string
    if itemProto == null
      logerr("Gun holder {itemProto} doesn't have item.proto")
      continue

    let itemId = *itemProto |> string() |> ecs_hash |> int()
    *weapInfo |> set("itemId", itemId)
