require ecs
require Gun
require common_shooter.events_common_shooter
require DagorMath

[es(no_order, tag=ui, REQUIRE=gun__timeBetweenShotsIsReload, REQUIRE_NOT=gun__reloadTime, REQUIRE=turretInput)]
def turret_shell_reload_progress(info : CmdGunUpdate;
                                 gun : Gun;
                                 turret__lastShellChangeTime : float = 0.0;
                                 turret__shellChangeInReloadDelay : float = 0.0;
                                 var ui_turret_reload_progress__progressStopped : float&;
                                 var ui_turret_reload_progress__startTime : float&;
                                 var ui_turret_reload_progress__finishTime : float&)
  ui_turret_reload_progress__finishTime = gun.nextShotAtTime > info.atTime ? gun.nextShotAtTime : -1.0
  ui_turret_reload_progress__startTime = ui_turret_reload_progress__finishTime - gun.timeBetweenShots
  if info.atTime > turret__lastShellChangeTime + turret__shellChangeInReloadDelay
    ui_turret_reload_progress__progressStopped = -1.0
  else
    let resumeTime = turret__lastShellChangeTime + turret__shellChangeInReloadDelay
    ui_turret_reload_progress__progressStopped = safediv(resumeTime - ui_turret_reload_progress__startTime, gun.timeBetweenShots)

[es(tag=ui, REQUIRE=turretInput, track=(gun__reloadStartTime, gun__reloadFinishTime))]
def turret_reloadable_reload_progress(evt : Event;
                                      gun__reloadStartTime : float;
                                      gun__reloadFinishTime : float;
                                      var ui_turret_reload_progress__progressStopped : float&;
                                      var ui_turret_reload_progress__startTime : float&;
                                      var ui_turret_reload_progress__finishTime : float&)
  ui_turret_reload_progress__progressStopped = -1.0
  ui_turret_reload_progress__startTime = gun__reloadStartTime
  ui_turret_reload_progress__finishTime = gun__reloadFinishTime
