require ecs
require ecs.common
require strings
require enlisted.events_enlisted

[es(tag=ui, REQUIRE=vehicleWithWatched, no_order)]
def ui_update_wathed_vehicle_turret_ammo(info : ParallelUpdateFrameDelayed;
                                         turret_control__gunEids : EidList;
                                         ui_turrets_state__updateInterval : float = 0.1;
                                         disableVehicleResupply : Tag const?;
                                         fortification_repair__costPercent : float const?;
                                         var ui_turrets_state__ammo : Object&;
                                         var ui_turrets_state__nextUpdateTime : float&)
  if info.curTime < ui_turrets_state__nextUpdateTime
    return
  ui_turrets_state__nextUpdateTime = info.curTime + ui_turrets_state__updateInterval
  var groupAmmo : table<string; int>
  var reloadAmmo : table<string; int>
  var firstLoadedGunInGroup : table<string; EntityId>
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__ammo : int;
                             gun__totalAmmo : int;
                             turret__numAmmoFirstStage : int = -1;
                             turret__groupName : string = "";
                             gun__ammo_by_shell : IntList const?)
      if !empty(turret__groupName)
        if !key_exists(groupAmmo, turret__groupName)
          groupAmmo[turret__groupName] = 0
        groupAmmo[turret__groupName] += gun__ammo
        reloadAmmo[turret__groupName] += gun__totalAmmo
        if gun__ammo > 0 && !key_exists(firstLoadedGunInGroup, turret__groupName)
          firstLoadedGunInGroup[turret__groupName] = gunEid
      ui_turrets_state__ammo |> push_to_object("{gunEid}") <| $(var ammo : Object)
        ammo |> set("curAmmo", gun__ammo)
        ammo |> set("totalAmmo", gun__totalAmmo)
        if turret__numAmmoFirstStage >= 0
          ammo |> set("firstStageAmmo", turret__numAmmoFirstStage)
        ammo |> set("canBeResuppliedOnPoint", disableVehicleResupply == null)
        ammo |> set("canBeResuppliedByEngineer", fortification_repair__costPercent != null)
        if gun__ammo_by_shell != null
          ammo |> set("ammoByBullet", *gun__ammo_by_shell)
    for group in keys(groupAmmo)
      ui_turrets_state__ammo |> push_to_object(group) <| $(var ammo : Object)
        ammo |> set("groupAmmo", groupAmmo[group])
        ammo |> set("reloadAmmo", reloadAmmo[group])
        if key_exists(firstLoadedGunInGroup, group)
          ammo |> set("firstLoadedGunInGroup", firstLoadedGunInGroup[group])
