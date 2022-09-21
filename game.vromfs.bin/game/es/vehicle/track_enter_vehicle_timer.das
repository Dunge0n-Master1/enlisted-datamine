require ecs

[es(tag=server, track=enter_vehicle__atTime)]
def track_enter_vehicle_timer_server(evt : Event; enter_vehicle__atTime : float; var enter_vehicle__timerEnabled : bool&)
  enter_vehicle__timerEnabled = enter_vehicle__atTime > 0.f

[es(tag=gameClient, track=enter_vehicle__timerEnabled)]
def track_enter_vehicle_timer_client(evt : Event; var enter_vehicle__atTime : float&; enter_vehicle__timerEnabled : bool)
  if !enter_vehicle__timerEnabled
    enter_vehicle__atTime = -1.f
