require ecs
require DngHuman
require HumanPhys
require Dacoll

[es(tag=server, no_order)]
def stop_burning_underwater(info : UpdateStageInfoAct;
                            human_net_phys : HumanActor;
                            transform : float3x4;
                            burning__extinguishWaterLevelStand : float;
                            burning__extinguishWaterLevelCrouch : float;
                            burning__extinguishWaterLevelCrawl : float;
                            var burning__underwaterNextCheckTime : float&;
                            var burning__isBurning : bool&;
                            burning__underwaterCheckPeriod : float = 1.0)
  if !burning__isBurning
    return
  if info.curTime < burning__underwaterNextCheckTime
    return
  burning__underwaterNextCheckTime = info.curTime + burning__underwaterCheckPeriod

  assume state = human_net_phys.phys.currentState

  var waterLevel = 0.f;
  let pos = transform[3]
  let posWithOffset = pos - state.posOffset
  if traceht_water(posWithOffset, waterLevel)
    waterLevel -= (pos.y - state.posOffset.y);

  var posHeight = burning__extinguishWaterLevelStand
  if state.height < -0.5
    posHeight = burning__extinguishWaterLevelCrawl
  elif state.height < 0.5
    posHeight = burning__extinguishWaterLevelCrouch

  if waterLevel > posHeight
    burning__isBurning = false