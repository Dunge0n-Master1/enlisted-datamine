require ecs

[es(tag=ui, REQUIRE=turretInput, on_appear, track=(turret__replenishmentStartTime, turret__replenishmentFinishTime))]
def turre_replenishment_progress_start_end(evt : Event;
                                           turret__replenishmentStartTime : float;
                                           turret__replenishmentFinishTime : float;
                                           var ui_turret_replenishment_progress__startTime : float&;
                                           var ui_turret_replenishment_progress__finishTime : float&)
  ui_turret_replenishment_progress__startTime = turret__replenishmentStartTime
  ui_turret_replenishment_progress__finishTime = turret__replenishmentFinishTime
