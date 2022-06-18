require ecs
require vehicle
require math.base
require DagorMath

[es(tag=render)]
def vehicle_tracks_visual_pos_es(info : UpdateStageInfoAct;
                                 vehicle_net_phys : VehiclePhysActor;
                                 var vehicle_tracks_visual_pos : float2&;
                                 var vehicle_tracks_visual_pos_delta : float2&)
  assume curState = vehicle_net_phys.phys.currentState
  assume prevState = vehicle_net_phys.phys.previousState

  let timeStep = vehicle_net_phys.phys.timeStep
  let curPhysTime = float(curState.atTick) * timeStep
  let prevPhysTime = float(prevState.atTick) * timeStep

  let k = safediv(info.curTime - prevPhysTime, curPhysTime - prevPhysTime)

  vehicle_tracks_visual_pos_delta.x = -vehicle_tracks_visual_pos.x
  vehicle_tracks_visual_pos_delta.y = -vehicle_tracks_visual_pos.y
  vehicle_tracks_visual_pos.x = lerp(prevState.leftTrack.pos, curState.leftTrack.pos, k)
  vehicle_tracks_visual_pos.y = lerp(prevState.rightTrack.pos, curState.rightTrack.pos, k)
  vehicle_tracks_visual_pos_delta.x += vehicle_tracks_visual_pos.x
  vehicle_tracks_visual_pos_delta.y += vehicle_tracks_visual_pos.y