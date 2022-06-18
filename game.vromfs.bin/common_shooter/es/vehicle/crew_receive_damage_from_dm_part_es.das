require ecs
require dm
require ecs.common

[es(on_appear, before=crew_hp_after_hit_es)]
def crew_receive_damage_from_dm_part_es(evt : Event;
                                        [[shared_comp]] vehicle_seats__seats : Array;
                                        var vehicle_seats_receive_damage_from_dm_part : IntList&;
                                        damage_model : DamageModel)
  resize(vehicle_seats_receive_damage_from_dm_part, length(vehicle_seats__seats))
  var seatNo = 0
  for child in vehicle_seats__seats
    let seat = get_ecs_object(child)
    var partId = -1
    let partName = get_string(seat, "receiveDamageFromDMPart", "")
    if partName != ""
      partId = find_part_id_by_name(damage_model, partName)
    vehicle_seats_receive_damage_from_dm_part[seatNo++] = partId
