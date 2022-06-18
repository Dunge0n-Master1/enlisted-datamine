require ecs

[es(tag=server, REQUIRE=fire_damage__doNotDamageCrew, on_appear, after=crew_receive_damage_from_dm_part_es)]
def init_fire_no_damage_parts_for_crew(evt : Event;
                                       vehicle_seats_receive_damage_from_dm_part : IntList;
                                       var fire_damage__burnWithoutDamageParts : IntList&)
  for partId in vehicle_seats_receive_damage_from_dm_part
    fire_damage__burnWithoutDamageParts |> push(partId)