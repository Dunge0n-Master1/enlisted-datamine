require ecs

[es(tag=server, track=pve_stage__enemyCount, REQUIRE=pve__active)]
def pve_stage_bot_count_change(evt : Event; eid : EntityId; pve_stage__enemyCount : int)
  if pve_stage__enemyCount > 0
    return

  removeSubTemplate(eid, "pve_active")
  find_query() <| $ [es(REQUIRE=pve__active)] (var pve_wave__currentStageId : int&)
    pve_wave__currentStageId += 1
    return true

[es(tag=server, after=pve_wave_activate_es, REQUIRE_NOT=pve__active)]
def pve_stage_timer_es(info : UpdateStageInfoAct;
                       eid : EntityId;
                       var pve_stage__delayTimer : float&)
  if pve_stage__delayTimer < 0f
    return

  pve_stage__delayTimer -= info.dt
  if pve_stage__delayTimer > 0f
    return

  addSubTemplate(eid, "pve_active")
