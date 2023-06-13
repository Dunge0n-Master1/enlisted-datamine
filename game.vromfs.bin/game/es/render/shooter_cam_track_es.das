require ecs

[es(tag=render, track=camera__target, REQUIRE=camera__target)]
def shooter_cam_track_es(evt : Event;
                         shooter_cam__tauOnChange : float;
                         var shooter_cam__tauInc : float&)
  if shooter_cam__tauOnChange > 0.0f
    shooter_cam__tauInc = shooter_cam__tauOnChange