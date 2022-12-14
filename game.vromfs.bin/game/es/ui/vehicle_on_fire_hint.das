require ecs
require game.events_game

[es(tag=ui, REQUIRE=vehicleWithWatched, REQUIRE_NOT=deadEntity, track=fire_damage__isBurn)]
def ui_vehicle_on_fire_hint(evt : Event; fire_damage__isBurn : bool)
  if fire_damage__isBurn
    query() <| $ [es(REQUIRE=watchedByPlr)] (squad_member__squad : EntityId)
      if (get_bool(squad_member__squad, "squad__isAlive") ?? false)
        broadcastEvent([[CmdShowHint event="PlayerVehicleOnFire", text="PlayerVehicleOnFire", ttl=10.0, unique="vehicle_on_fire"]])
  else
    broadcastEvent([[CmdShowHint event="PlayerVehicleOnFire", unique="vehicle_on_fire"]])

[es(tag=ui, REQUIRE=vehicleWithWatched, REQUIRE_NOT=deadEntity, on_disappear)]
def ui_hide_vehicle_on_fire_hint(evt : Event)
  broadcastEvent([[CmdShowHint event="PlayerVehicleOnFire", unique="vehicle_on_fire"]])

[es(tag=ui, track=squad__isAlive)]
def ui_hide_vehicle_on_fire_hint_squad_is_dead(evt : Event; eid aka squad_eid : EntityId; squad__isAlive : bool)
  if !squad__isAlive
    query() <| $ [es(REQUIRE=watchedByPlr)] (squad_member__squad : EntityId)
      if squad_eid == squad_member__squad
        broadcastEvent([[CmdShowHint event="PlayerVehicleOnFire", unique="vehicle_on_fire"]])
