module human_gun_common shared
require ecs
require ecs.extra_set
require EnlistedNet
require common_shooter.events_common_shooter
require Gun
require DaWeaponProps

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

def create_shell_entity(templ_name : string; in_tm : float3x4; start_vel : float3;
                        owner_eid : EntityId; shell_id : ShellPropIds |#; gun_props_id : int;
                        launch_time : float; expl_time : float; in_active : bool;
                        client_side : bool;  rethrower_eid : EntityId)
  return createEntity("{templ_name}+{client_side ? "client_side" : "replicating"}") <| $(var init)
    init |> set("transform", in_tm)
    init |> set("start_vel", start_vel)
    init |> set("shell__shell_id__shell_id", int(shell_id.shellId))
    init |> set("shell__shell_id__damage_id", int(shell_id.damageId))
    init |> set("shell__shell_id__ballistics_id", int(shell_id.ballisticsId))
    init |> set("shell__gun_props_id", gun_props_id)
    init |> set("shell__owner", owner_eid)
    init |> set("shell__rethrower", rethrower_eid)
    init |> set("shell__launchAtTime", launch_time)
    init |> set("shell__explTime", expl_time)
    init |> set("animchar_render__enabled", in_active)
    init |> set("active", in_active)
    if !!owner_eid
      init |> set("ignoreObjs__time", 0.01f)
      init |> set("ignoreObjs__eids", [{auto owner_eid}])
