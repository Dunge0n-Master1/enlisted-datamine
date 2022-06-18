require ecs
require game.events_game
require DaWeaponProps
require EnlistedDm

[es(tag=render, REQUIRE=watchedByPlr)]
def set_death_cam_killer(evt : EventEntityDied; var death_cam__killer : EntityId&)
  death_cam__killer = evt.offender
  let gunStatType = get_gun_stat_type_by_props_id(evt.gunPropsId)
  if gunStatType == "artillery"
    death_cam__killer = INVALID_ENTITY_ID
    return
  if evt.shellId < 0
    return
  shell_entity_get_props(evt.shellId) <| $(shellEntityProps : ShellEntityTypeProps)
    let templateName = shellEntityProps.templName
    let shellTemplate = getTemplateByName(templateName)
    if shellTemplate != null
      let isKillerCamAllowed = *shellTemplate |> getTemplateComponent("shell__isKillerCamAllowed") |> get_bool ?? true
      if !isKillerCamAllowed
        death_cam__killer = INVALID_ENTITY_ID
