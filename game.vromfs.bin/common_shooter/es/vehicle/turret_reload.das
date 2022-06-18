require ecs
require app
require DaWeaponProps
require game.es.vehicle.vehicle_events

def reload_gun_now(var gun__ammo : int&;
                   var gun__totalAmmo : int&;
                   var gun__reloadFinishTime : float&;
                   gun__maxAmmo : int)
  let ammoToLoad = min(gun__totalAmmo, gun__maxAmmo) - gun__ammo
  if ammoToLoad > 0
    gun__totalAmmo -= ammoToLoad
    gun__ammo += ammoToLoad
  gun__reloadFinishTime = -1.0

def start_reload_timer(gun__reloadTime : float; var gun__reloadStartTime : float&; var gun__reloadFinishTime : float&)
  gun__reloadStartTime = get_sync_time()
  gun__reloadFinishTime = gun__reloadStartTime + gun__reloadTime

[es(tag=server, no_order, REQUIRE=isTurret)]
def turret_reload_update(info : UpdateStageInfoAct;
                         var gun__ammo : int&;
                         var gun__totalAmmo : int&;
                         var gun__reloadFinishTime : float&;
                         gun__maxAmmo : int)
  if gun__reloadFinishTime > 0.0 && info.curTime >= gun__reloadFinishTime
    reload_gun_now(gun__ammo, gun__totalAmmo, gun__reloadFinishTime, gun__maxAmmo)

[es(tag=server, REQUIRE=isTurret, REQUIRE_NOT=forbidReloadIfNotEmpty)]
def turret_start_reload_timer(evt : CmdTurretStartReloading;
                              gun__totalAmmo : int;
                              var gun__reloadStartTime : float&;
                              var gun__reloadFinishTime : float&;
                              gun__reloadTime : float)
  if gun__totalAmmo > 0
    start_reload_timer(gun__reloadTime, gun__reloadStartTime, gun__reloadFinishTime)

[es(tag=server, REQUIRE=isTurret, REQUIRE=forbidReloadIfNotEmpty)]
def turret_start_reload_timer_not_empty(evt : CmdTurretStartReloading;
                                        gun__ammo : int;
                                        gun__totalAmmo : int;
                                        var gun__reloadStartTime : float&;
                                        var gun__reloadFinishTime : float&;
                                        gun__reloadTime : float)
  if gun__ammo <= 0 && gun__totalAmmo > 0
    start_reload_timer(gun__reloadTime, gun__reloadStartTime, gun__reloadFinishTime)

[es(tag=server, REQUIRE=(isTurret, gunAutoReloadOnEmpty), track=gun__ammo)]
def turret_reload_on_empty(evt : Event; eid : EntityId; gun__ammo : int)
  if gun__ammo <= 0
    sendEvent(eid, [[CmdTurretStartReloading]])

[es(tag=server, REQUIRE=(isTurret, currentBulletId), after=turret_on_change_current_shell_reloadable_es, track=currentBulletId)]
def turret_reload_on_type_change(evt : Event; eid : EntityId)
  sendEvent(eid, [[CmdTurretStartReloading]])
