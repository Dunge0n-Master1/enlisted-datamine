require ecs
require ecs.common
require app
require vehicle

[es(tag=gameClient, on_appear)]
def entities_in_victim_tank_es(evt : Event;
                               hitcamera__target : EntityId;
                               hitcamera__crew_hp_after_hit : IntList;
                               var hitcamera__deadMembers : int&;
                               var hitcamera__totalMembersBeforeShot : int&)
  var totalCrewCount = 0
  var deadCrewCount = 0
  query(hitcamera__target) <| $ [es] (vehicle_seats__seatEids : EidList)
    for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      let hp = hitcamera__crew_hp_after_hit[seatNo]
      if !!ownerEid
        totalCrewCount++
        if hp == 0
          deadCrewCount++
  hitcamera__deadMembers = deadCrewCount
  hitcamera__totalMembersBeforeShot = totalCrewCount
