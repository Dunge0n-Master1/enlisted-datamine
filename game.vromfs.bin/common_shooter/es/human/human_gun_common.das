module human_gun_common shared
require ecs
require EnlistedNet
require common_shooter.events_common_shooter
require Gun

def human_gun_update_reload(gun : Gun;
                            gun_eid : EntityId;
                            gun__manuallyUnloaded : bool;
                            shoot : bool;
                            is_for_real : bool;
                            gun_ammo : int;
                            gun_owner : EntityId;
                            at_time : float)
  if is_server() && is_for_real && gun_ammo == 0
    let reloadOnShoot = get_bool(gun_owner, "human_weap__reloadOnShoot") ?? true
    let reloadOnEmptyMag = get_bool(gun_owner, "human_weap__reloadOnEmptyMag") ?? true
    var shouldReload = false

    if reloadOnShoot
      shouldReload ||= !gun.appliedControls.shoot && shoot

    if reloadOnEmptyMag && !gun__manuallyUnloaded
      shouldReload ||= !shoot

    if shouldReload
      sendEventImmediate(gun_owner, [[CmdRequestReload atTime=at_time, gunEid=gun_eid]])
