require ecs

// Why: In replay mode we have a bug with fps camera in vehicle
// fps camera work same as tps, but vehicle part is hidden. So enable all vehicle part for now
[es(tag=playingReplay, on_appear, on_disappear, on_event=EventOnSeatOwnersChanged, REQUIRE=heroVehicle, after=vehicle_is_cockpit_seat)]
def replay_disable_hero_cockpit(evt : Event; var cockpit__isHeroInCockpit : bool&)
  cockpit__isHeroInCockpit = false
