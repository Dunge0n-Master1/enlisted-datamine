require ecs
require common_shooter.events_common_shooter
require DagorSystem
require DaWeapons


def create_cmd_net_shot(launch_desc : LaunchDesc)
  return <- [[CmdNetShot
    shellId=launch_desc.shellId.shellId,
    damageId=launch_desc.shellId.damageId,
    ballisticsId=launch_desc.shellId.ballisticsId,
    gunPropsId=launch_desc.gunPropsId,
    atTime=launch_desc.atTime,
    initialLifeTime=launch_desc.initialLifeTime,
    tm=launch_desc.tm,
    vel=launch_desc.vel,
    firingMode=launch_desc.firingMode,
    bombBayHeight=launch_desc.bombBayHeight]]


def create_turret_shot_shell_msg(turretNo : int; launch_desc : LaunchDesc)
  return <- [[TurretShotShellMsg
    turretNo=turretNo,
    shellId=launch_desc.shellId.shellId,
    damageId=launch_desc.shellId.damageId,
    ballisticsId=launch_desc.shellId.ballisticsId,
    gunPropsId=launch_desc.gunPropsId,
    atTime=launch_desc.atTime,
    initialLifeTime=launch_desc.initialLifeTime,
    tm=launch_desc.tm,
    vel=launch_desc.vel,
    firingMode=launch_desc.firingMode,
    bombBayHeight=launch_desc.bombBayHeight]]


[es(tag=(server, net), after=after_guns_update_sync, before=clear_gun_launch_events_es)]
def net_shot_listener_es(info : UpdateStageInfoAct;
                         human_weap__gunEids : EidList)
  for gunEid in human_weap__gunEids
    query(gunEid) <| $ [es] (gun_launch_events : GunLaunchEvents)
      for event in gun_launch_events.launchEvents
        sendEvent(gunEid, create_cmd_net_shot(event))


[es(tag=(server, net), after=after_guns_update_sync, before=clear_gun_launch_events_es)]
def net_turret_shot_listener_es(info : UpdateStageInfoAct;
                                eid : EntityId;
                                turret_control__gunEids : EidList)
  for turretNo in iter_range(turret_control__gunEids)
    query(turret_control__gunEids[turretNo]) <| $ [es] (gun_launch_events : GunLaunchEvents)
      for event in gun_launch_events.launchEvents
        sendEvent(eid, create_turret_shot_shell_msg(turretNo, event))


[es(tag=(server, net), after=after_guns_update_sync, before=clear_gun_launch_events_es, REQUIRE=autoShoot)]
def net_auto_shot_listener_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              gun_launch_events : GunLaunchEvents)
  for event in gun_launch_events.launchEvents
    sendEvent(eid, create_cmd_net_shot(event))
