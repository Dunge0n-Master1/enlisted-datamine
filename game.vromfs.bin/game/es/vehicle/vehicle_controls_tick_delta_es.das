require ecs
require math
require player
require DagorConsole
require DagorSystem
require DngActor

[es(tag=server, no_order)]
def vehicle_phys_calc_controls_tick_delta_es(evt : UpdateStageInfoAct;
                                             vehicle_seats__seatEids : EidList;
                                             var net__controlsTickDelta : int&)
  var maxControlsTickDelta = 0
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__playerEid : EntityId)
      query(seat__playerEid) <| $ [es] (var player : Player)
        maxControlsTickDelta = max(maxControlsTickDelta,
                                   player |> calcControlsTickDelta(PhysTickRateType Normal, false))

  net__controlsTickDelta = maxControlsTickDelta
