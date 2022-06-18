require ecs

[es(tag=server, on_appear)]
def override_offender_clear_time(evt : Event;
                                 overrideClearOffenderTimer : float;
                                 var hitpoints__clearOffenderTimer : float&;
                                 var backupClearOffenderTimer : float&)
  backupClearOffenderTimer = hitpoints__clearOffenderTimer
  hitpoints__clearOffenderTimer = overrideClearOffenderTimer

[es(tag=server, on_disappear)]
def restore_offender_clear_time(evt : Event;
                                backupClearOffenderTimer : float;
                                var hitpoints__clearOffenderTimer : float&)
  hitpoints__clearOffenderTimer = backupClearOffenderTimer
