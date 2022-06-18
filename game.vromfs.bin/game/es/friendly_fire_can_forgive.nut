import "%dngscripts/ecs.nut" as ecs
ecs.register_es("friendly_fire_track_players_can_forgive_server",
  { [["onInit", "onChange"]] = @(_, comp)
      comp["friendly_fire__canForgivePlayers"] = comp["friendly_fire__forgivableStats"].getAll().map(@(stats) stats.len() > 0)
  },
  {
    comps_track = [["friendly_fire__forgivableStats", ecs.TYPE_OBJECT]]
    comps_rw = [["friendly_fire__canForgivePlayers", ecs.TYPE_OBJECT]]
  },
  {tags="server"})
