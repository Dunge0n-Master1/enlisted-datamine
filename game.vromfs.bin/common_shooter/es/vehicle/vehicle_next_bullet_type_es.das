require ecs
require app
require DaWeaponProps
require Gun
require DngWeapon
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter

def should_change_shell_after_shot(gun_eid : EntityId; gun__reloadable : bool; ammo, currentBulletId, nextBulletId : int)
  let canReload = !gun__reloadable || ammo == 0 || !has(gun_eid, "forbidReloadIfNotEmpty")
  return currentBulletId != nextBulletId && canReload

def find_next_available_bullet_id(current_index : int; ammo : IntList; ammo_set_length : int)
  let rangeEnd = min(length(ammo), ammo_set_length)
  for i in range(current_index + 1, rangeEnd)
    if ammo[i] > 0
      return i
  for i in range(0, min(current_index, rangeEnd))
    if ammo[i] > 0
      return i
  return current_index


[es(tag=server)]
def next_bullet_id_request_es(evt : CmdNextBulletIdRequest; eid : EntityId)
  let vehicleEid = eid
  query() <| $ [es] (gun : Gun;
                     eid : EntityId;
                     var nextBulletId : int&;
                     var currentBulletId : int&;
                     turret__owner : EntityId;
                     gun__ammoSets : Array;
                     gun__ammo_by_shell : IntList;
                     turret__triggerGroup : int;
                     gun__reloadFinishTime : float const?)
    if turret__owner == vehicleEid && turret__triggerGroup == evt.triggerGroup
      nextBulletId = find_next_available_bullet_id(nextBulletId, gun__ammo_by_shell, length(gun__ammoSets))
      sendEvent(vehicleEid, [[EventOnSelectNextBulletId gunEid=eid, nextBulletId=nextBulletId]])
      let isReloadChange = gun__reloadFinishTime ?? gun.nextShotAtTime > get_sync_time()
      let isCurrentShellTypeDepleted = currentBulletId < length(gun__ammo_by_shell) && gun__ammo_by_shell[currentBulletId] <= 0
      if isCurrentShellTypeDepleted || isReloadChange
        currentBulletId = nextBulletId

[es(track=currentBulletId, REQUIRE=currentBulletId, before=turret_on_change_current_shell_es)]
def change_bullet_id_during_between_shots_delay(evt : Event;
                                                var gun : Gun;
                                                gun__ammo : int;
                                                var turret__lastShellChangeTime : float&;
                                                turret__shellChangeInReloadDelay : float = 1.0;
                                                turret__canChangeShellDuringReload : bool = false)
  if gun__ammo == 0
    return

  let curTime = get_sync_time()
  let nextShotAtTime = gun.nextShotAtTime

  if nextShotAtTime <= curTime
    return

  if turret__canChangeShellDuringReload
    let delay = min(curTime - turret__lastShellChangeTime, turret__shellChangeInReloadDelay)
    turret__lastShellChangeTime = curTime
    gun_force_next_shot_time(gun, nextShotAtTime + delay)
  else
    gun_force_next_shot_time(gun, curTime + gun.curState.timeBetweenShots)

[es(track=currentBulletId, REQUIRE=currentBulletId, before=turret_on_change_current_shell_reloadable_es)]
def change_bullet_id_during_reload_delay(evt : Event;
                                         gun__totalAmmo : int;
                                         gun__reloadTime : float;
                                         var gun__reloadStartTime : float&;
                                         var gun__reloadFinishTime : float&;
                                         var turret__lastShellChangeTime : float&;
                                         turret__shellChangeInReloadDelay : float = 1.0;
                                         turret__canChangeShellDuringReload : bool = false)
  if gun__totalAmmo == 0
    return

  let curTime = get_sync_time()

  if gun__reloadFinishTime <= curTime
    return

  if turret__canChangeShellDuringReload
    let delay = min(curTime - turret__lastShellChangeTime, turret__shellChangeInReloadDelay)
    turret__lastShellChangeTime = curTime
    gun__reloadFinishTime += delay
  else
    gun__reloadFinishTime = curTime + gun__reloadTime
  gun__reloadStartTime = gun__reloadFinishTime - gun__reloadTime

[es(tag=server, track=gun__ammo_by_shell, on_appear, after=gun_init_es, after=turret_gun_es)]
def turret_bullet_id_es(evt : Event;
                        eid : EntityId;
                        var nextBulletId : int&;
                        var currentBulletId : int&;
                        var lastBulletId : int&;
                        gun__ammoSets : Array;
                        gun__ammo : int;
                        gun__ammo_by_shell : IntList;
                        gun__reloadable : bool = false)
  lastBulletId = currentBulletId
  if length(gun__ammo_by_shell) == 0
    return
  if currentBulletId == nextBulletId && gun__ammo_by_shell[currentBulletId] == 0
    for i in iter_range(gun__ammoSets)
      if i != currentBulletId && gun__ammo_by_shell[i] >= 1
        nextBulletId = i
        break
  if should_change_shell_after_shot(eid, gun__reloadable, gun__ammo, currentBulletId, nextBulletId)
    currentBulletId = nextBulletId
