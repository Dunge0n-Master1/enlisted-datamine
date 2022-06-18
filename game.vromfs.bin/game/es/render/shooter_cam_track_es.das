require ecs

[es(tag=render, track=camera__target, REQUIRE=camera__target)]
def shooter_cam_track_es(evt : Event;
                         shooter_cam__tauOnChange : float;
                         var shooter_cam__tauInc : float&)
  shooter_cam__tauInc = shooter_cam__tauOnChange