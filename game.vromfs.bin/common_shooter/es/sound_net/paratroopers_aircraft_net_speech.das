require ecs
require app
require human_sounds_net.modules.human_sounds_net_events
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require math.base
require DagorMath


[es(tag=server, on_appear, after=paratroopers_aircraft_set_kick_distance)]
def paratroopers_aircraft_net_speech_appear(evt : Event;
                                            var paratroopers_aircraft_net_speech__narratorGetReadyAt : float&;
                                            var paratroopers_aircraft_net_speech__narratorDistToKickParatroopersSq : float&;
                                            paratroopers_aircraft_net_speech__narratorGetReadyDelay : float;
                                            paratroopers_aircraft_net_speech__narratorDistToKickParatroopersOffset : float;
                                            ai_aircraft__distToKickParatroopers : float)
  paratroopers_aircraft_net_speech__narratorGetReadyAt = get_sync_time() + paratroopers_aircraft_net_speech__narratorGetReadyDelay
  paratroopers_aircraft_net_speech__narratorDistToKickParatroopersSq = square(sqrt(ai_aircraft__distToKickParatroopers) + paratroopers_aircraft_net_speech__narratorDistToKickParatroopersOffset)


[es(tag=server, before=check_paratroopers_aircraft_target)]
def paratroopers_aircraft_net_speech_update(info : UpdateStageInfoAct;
                                            vehicle_seats__seatEids : EidList;
                                            var paratroopers_aircraft_net_speech__narratorEnabled : bool&;
                                            var paratroopers_aircraft_net_speech__narratorGetReadyAt : float&;
                                            paratroopers_aircraft_net_speech__narratorDistToKickParatroopersSq : float;
                                            paratroopers_aircraft_net_speech__narratorFlyToKickTimerOffset : float;
                                            paratroopers_aircraft__flyToKickTimer : float;
                                            paratroopers_aircraft__kicked : bool;
                                            ai_aircraft__targetPos : float3;
                                            transform : float3x4)
  if paratroopers_aircraft_net_speech__narratorEnabled
    if !paratroopers_aircraft__kicked
      if distance_sq(transform[3].xz, ai_aircraft__targetPos.xz) < paratroopers_aircraft_net_speech__narratorDistToKickParatroopersSq || info.curTime >= paratroopers_aircraft__flyToKickTimer - paratroopers_aircraft_net_speech__narratorFlyToKickTimerOffset
        query(vehicle_seats__seatEids[0]) <| $ [es] (seat__ownerEid : EntityId)
          sendEvent(seat__ownerEid, [[CmdRequestHumanSpeech phrase="paratroopGo"]])
        paratroopers_aircraft_net_speech__narratorEnabled = false
      elif paratroopers_aircraft_net_speech__narratorGetReadyAt > 0. && info.curTime >= paratroopers_aircraft_net_speech__narratorGetReadyAt
        query(vehicle_seats__seatEids[0]) <| $ [es] (seat__ownerEid : EntityId)
          sendEvent(seat__ownerEid, [[CmdRequestHumanSpeech phrase="paratroopReady"]])
        paratroopers_aircraft_net_speech__narratorGetReadyAt = 0.
    else
      paratroopers_aircraft_net_speech__narratorEnabled = false


[es(tag=server, REQUIRE=paratroopersAircraft)]
def paratroopers_aircraft_net_speech_on_kicked(evt : CmdKickFromVehicle)
  sendEvent(evt.eid, [[CmdRequestHumanSpeech phrase="paratroopCry"]])
