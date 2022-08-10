require ecs
require app
require enlisted.events_enlisted

[es(tag=server, on_appear, track=pve__currentWaveId)]
def pve_wave_init_finish_es(evt : Event;
                            pve__waveDelay : float;
                            pve__currentWaveId : int;
                            pve__waves : StringList;
                            var pve__waveDelayTimer : float&)
  if uint(pve__currentWaveId) >= uint(length(pve__waves))
    broadcastEvent([[EventTeamWon team=1]])
    return

  pve__waveDelayTimer = pve__waveDelay

[es(tag=server, after=pve_wave_init_es)]
def pve_wave_timer_es(info : UpdateStageInfoAct;
                      pve__waves : StringList;
                      pve__currentWaveId : int;
                      var pve__waveDelayTimer : float&)
  if uint(pve__currentWaveId) >= uint(length(pve__waves))
    return

  if pve__waveDelayTimer < 0f
    return

  pve__waveDelayTimer -= info.dt
  if pve__waveDelayTimer > 0f
    return

  let wave = string(pve__waves[pve__currentWaveId])
  find_query() <| $ [es(REQUIRE_NOT=pve__active)] (eid : EntityId; pve_wave__name : string)
    if pve_wave__name == wave
      addSubTemplate(eid, "pve_active")
      return true
    return false

[es(tag=server, REQUIRE=pve__active, track=pve_wave__currentStageId, on_appear)]
def pve_wave_activate_es(evt : Event;
                         eid : EntityId;
                         pve_wave__stages : StringList;
                         pve_wave__currentStageId : int)
  if uint(pve_wave__currentStageId) >= uint(length(pve_wave__stages))
    removeSubTemplate(eid, "pve_active")
    query() <| $ [es] (var pve__currentWaveId : int&)
      pve__currentWaveId += 1
    return

  let stageId = pve_wave__currentStageId
  let stage = string(pve_wave__stages[stageId])
  find_query() <| $ [es] (pve_stage__name : string;
                          var pve_stage__delayTimer : float&)
    if pve_stage__name == stage
      query() <| $ [es] (pve__stageDelay : float)
        pve_stage__delayTimer = (stageId == 0 ? 0f : pve__stageDelay)
      return true
    return false
