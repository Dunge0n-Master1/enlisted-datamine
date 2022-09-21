require ecs
require dm

[es(tag=server, track=vehicle_flipped__isFlipped)]
def vehicle_lock_use(evt : Event;
                     var vehicle__isPlayerCanEnter : bool&;
                     vehicle_flipped__isFlipped : bool = false)
  vehicle__isPlayerCanEnter = !vehicle_flipped__isFlipped

def is_part_alive(damage_model : DamageModel; part_no : int)
  return part_no < 0 || uint(get_rel_hp_fixed(damage_model.dmData, part_no)) != 0u

[es(tag=server, REQUIRE=vehicle__lockIfTurretBroken, on_event=CmdTurretsUpdate)]
def vehicle_lock_use_broken_turret(evt : Event;
                                   damage_model : DamageModel;
                                   turret_control__gunEids : EidList;
                                   var vehicle__isPlayerCanEnter : bool&)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(mainTurret, resolvedTurret))] (turret__isBroken : bool;
                                                                   turret_drive_dm_part__horDriveDm : int;
                                                                   turret_drive_dm_part__verDriveDm : int)
      let canAim = (is_part_alive(damage_model, turret_drive_dm_part__horDriveDm) &&
                    is_part_alive(damage_model, turret_drive_dm_part__verDriveDm))
      vehicle__isPlayerCanEnter = !turret__isBroken && canAim