require ecs
require enlisted.events_enlisted
require sound_utils_net.modules.sound_desc_common
require game.utils.hero
require soundSystem

def get_seat_impl(human_eid; seat_eids : EidList; seats : Array; name_id : string)
  for seatNo, seatEid in iter_range(seat_eids), seat_eids
    if human_eid == (get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID)
      return get_string(get_ecs_object(seats[seatNo]), name_id, "")
  return ""

def get_seat_loc_name(human_eid; seat_eids : EidList; seats : Array)
  return get_seat_impl(human_eid, seat_eids, seats, "locName")

[es(tag=sound, on_event=EventEntityDied, REQUIRE=vehicleSpeech)]
def vehicle_speech_teammate_died(evt : Event;
                                 eid, human_anim__vehicleSelected : EntityId)
  if !has(eid, "hero")
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList; [[shared_comp]] vehicle_seats__seats : Array)
      let vehicleSelected = human_anim__vehicleSelected
      find_query() <| $ [es(REQUIRE=hero)] (eid aka vehicle_eid : EntityId; human_anim__vehicleSelected : EntityId)
        if vehicleSelected == human_anim__vehicleSelected // player is in same vehicle as dead human
          let locName = get_seat_loc_name(eid, vehicle_seats__seatEids, vehicle_seats__seats)
          if locName != ""
            sendEvent(vehicle_eid, [[CmdHeroSpeech phrase="vehicleMateDied/{locName}"]])
        return true


[es(tag=sound, track=fire_damage__isBurn, REQUIRE=vehicleSpeech)]
def vehicle_speech_vehicle_burn(evt : Event;
                                eid aka vehicle_eid : EntityId;
                                isExploded : bool;
                                fire_damage__isBurn : bool)
  if !isExploded && fire_damage__isBurn
    find_query() <| $ [es(REQUIRE=hero)] (eid aka hero_eid : EntityId; human_anim__vehicleSelected : EntityId)
      if human_anim__vehicleSelected == vehicle_eid
        sendEvent(hero_eid, [[CmdHeroSpeech phrase="vehicleFire"]])
      return true
