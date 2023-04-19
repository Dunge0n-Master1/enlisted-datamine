require game.es.events
require vehicle
require DngWeapon
require game.utils.hero
require app
require ecs
require danetlibs.native_dasevents.main.native_events


[es(tag=gameClient, REQUIRE=resolvedTurret, track=turret_input__shootFlag)]
def vehicle_turret_unusable_notification_es(evt : Event;
                                            turret__owner : EntityId;
                                            turret_input__shootFlag : bool;
                                            turret__isUnderwater : bool;
                                            turret__isBroken : bool)
  if !turret_input__shootFlag || (!turret__isBroken && !turret__isUnderwater)
    return

  query(turret__owner) <| $ [es] (vehicle__localControls : VehicleControlsState;
                                  shootingBlockNotificationTime : int;
                                  var lastBlockNotificationAtTime : float&)
    let curTime = get_sync_time()
    let nextNofiticationAtTime = lastBlockNotificationAtTime + float(shootingBlockNotificationTime)
    if curTime < nextNofiticationAtTime || !can_control_turrets(vehicle__localControls)
      return

    let hero = get_controlled_hero()
    if turret__isBroken
      sendEvent(hero, [[CmdHeroLogEvent event="vehicle_turret_shoot_blocked", text="vehicle/vehicle_turret_shoot_blocked", ttl=shootingBlockNotificationTime]])
    elif turret__isUnderwater
      sendEvent(hero, [[CmdHeroLogEvent event="vehicle_turret_shoot_blocked_underwater", text="vehicle/vehicle_turret_shoot_blocked_underwater", ttl=shootingBlockNotificationTime]])
    lastBlockNotificationAtTime = get_sync_time()