require ecs
require ecs.safe
require DaWeaponProps
require DngDm
require common_shooter.events_common_shooter
require common_shooter.es.hit_result_common

[es(tag=render, REQUIRE=watchedByPlr)]
def set_death_cam_killer(evt : EventOnEntityHit; eid : EntityId; var death_cam__killer : EntityId&)
  if (evt.hitResult != int(HitResult HIT_RES_KILLED) && evt.hitResult != int(HitResult HIT_RES_DOWNED)) || evt.victim != eid
    return

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
      let isKillerCamAllowed = *shellTemplate |> getTemplateComponent("shell__isKillerCamAllowed") ?? true
      if !isKillerCamAllowed
        death_cam__killer = INVALID_ENTITY_ID
