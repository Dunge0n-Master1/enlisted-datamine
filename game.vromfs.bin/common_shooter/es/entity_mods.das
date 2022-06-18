require ecs
require common_shooter.es.entity_mods_common

[es(on_event=EventOnModsChanged)]
def entity_aim_speed_mult(evt : Event; var entity_mods__aimSpeedMult : float&; entity_mods__aimSpeedMods : Object;
                          allowedMods : StringList?)
  entity_mods__aimSpeedMult = calc_change_mult_attr(entity_mods__aimSpeedMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_sprint_speed_mult(evt : Event; var entity_mods__sprintSpeedMult : float&; entity_mods__sprintSpeedMultMods : Object;
                             allowedMods : StringList?)
  entity_mods__sprintSpeedMult = calc_diminishing_change_mult_attr(entity_mods__sprintSpeedMultMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_speed_mult(evt : Event; var entity_mods__speedMult : float&; entity_mods__speedMultMods : Object;
                      allowedMods : StringList?)
  entity_mods__speedMult = calc_diminishing_change_mult_attr(entity_mods__speedMultMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_change_weapon_mult(evt : Event; var entity_mods__fasterChangeWeaponMult : float&; entity_mods__changeWeaponSpeedMods : Object;
                              allowedMods : StringList?)
  entity_mods__fasterChangeWeaponMult = calc_diminishing_change_mult_attr(entity_mods__changeWeaponSpeedMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_item_use_time_mult(evt : Event; var entity_mods__itemUseTimeMult : float&; entity_mods__itemUseTimeMods : Object;
                              allowedMods : StringList?)
  entity_mods__itemUseTimeMult = calc_diminishing_change_mult_attr(entity_mods__itemUseTimeMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_target_use_time_mult(evt : Event; var entity_mods__targetUseTimeMult : float&; entity_mods__targetUseTimeMods : Object;
                                allowedMods : StringList?)
  entity_mods__targetUseTimeMult = calc_diminishing_change_mult_attr(entity_mods__targetUseTimeMods, allowedMods)

[es(on_event=EventOnModsChanged)]
def entity_change_pose_speed_mult(evt : Event; var entity_mods__fasterChangePoseMult : float&; entity_mods__changePoseSpeedMult : Object;
                                  allowedMods : StringList?)
  entity_mods__fasterChangePoseMult = calc_diminishing_change_mult_attr(entity_mods__changePoseSpeedMult, allowedMods)
