require ecs
require DagorMath
require DagorShaders

let
  redout_blackout_colorVarId = get_shader_variable_id("redout_blackout_color", true)

[es(tag=render, REQUIRE_NOT=deadEntity, REQUIRE=vehicleWithWatched, after=aircraft_crew_g_force_visual)]
def plane_landing_respawn_blackout_effect(info : UpdateStageInfoAct;
                                          plane_landing__repairTime : float;
                                          plane_landing__repairAtTime : float;
                                          plane_landing__respawnedAtTime : float;
                                          plane_landing_blackout__timeBeforeSpawn : float;
                                          plane_landing_blackout__timeAfterSpawn : float;
                                          plane_landing_blackout__progressMinMax : float2;
                                          plane_landing_blackout__fullBlackTime : float)
  if plane_landing__repairAtTime > 0.0
    let endTime = plane_landing__repairAtTime - plane_landing_blackout__fullBlackTime
    let startTime = min(endTime, plane_landing__repairAtTime - min(plane_landing__repairTime, plane_landing_blackout__timeBeforeSpawn))
    let progress = cvt(info.curTime,
      startTime, endTime,
      plane_landing_blackout__progressMinMax[0], plane_landing_blackout__progressMinMax[1])
    DagorShaders::set_color4(redout_blackout_colorVarId, 0.0, 0.0, 0.0, progress)
  elif info.curTime - plane_landing__respawnedAtTime < plane_landing_blackout__timeAfterSpawn
    let progress = cvt(info.curTime,
      plane_landing__respawnedAtTime, plane_landing__respawnedAtTime + plane_landing_blackout__timeAfterSpawn,
      plane_landing_blackout__progressMinMax[1], plane_landing_blackout__progressMinMax[0])
    DagorShaders::set_color4(redout_blackout_colorVarId, 0.0, 0.0, 0.0, progress)

[es(tag=render, REQUIRE_NOT=deadEntity, REQUIRE=(vehicleWithWatched, plane_landing__repairAtTime), on_disappear)]
def plane_landing_respawn_remove_blackout_effect(evt : Event)
  DagorShaders::set_color4(redout_blackout_colorVarId, 0.0, 0.0, 0.0, 0.0)
