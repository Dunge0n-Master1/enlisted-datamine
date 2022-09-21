require DagorSystem
require ecs
require game.es.vehicle.vehicle_seats_common
require game.utils.hero
require DagorShaders
require vehicle

let cockpit_girth_radiusVarId = get_shader_variable_id("cokpitRadius", true)

def set_cokpit_radius(radius)
  DagorShaders::set_real(cockpit_girth_radiusVarId, radius)

[es(tag=render, on_appear, on_event=(EventOnSeatOwnersChanged),
     track=(human_anim__vehicleSelected, isInVehicle, bindedCamera),
     REQUIRE=(hero, bindedCamera))]
def cockpit_inside_effects_control(evt : Event;
                                   human_anim__vehicleSelected : EntityId;
                                   isInVehicle : bool)
  var currentRadius = 0f
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                effectsCulling__cockpitRadius : float)
    currentRadius = effectsCulling__cockpitRadius
    let seatNo = find_seat_with_owner(get_controlled_hero(), vehicle_seats__seatEids)
    if seatNo >= 0
      query(vehicle_seats__seatEids[seatNo]) <| $ [es] (seats_hatch_nodes__isValid : bool = false; seats_hatch_nodes__openPos : float = 0.f)
        let hasHatch = seats_hatch_nodes__isValid
        let isHatchClosed = hasHatch && seats_hatch_nodes__openPos <= 0.f
        currentRadius = (!hasHatch || isHatchClosed) ? currentRadius : 0f

  currentRadius = isInVehicle ? currentRadius : 0f;
  set_cokpit_radius(currentRadius)

[es(tag=render, on_appear, track=(seats_hatch_nodes__openPos))]
def cockpit_open_hatch_effects_control(evt : Event; seats_hatch_nodes__isValid : bool; seats_hatch_nodes__openPos : float; eid : EntityId)
  let heroId = get_controlled_hero()
  query(heroId) <| $ [es] (human_anim__vehicleSelected : EntityId)
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                  effectsCulling__cockpitRadius : float)
      let seatNo = find_seat_with_owner(heroId, vehicle_seats__seatEids)
      if seatNo < 0
        set_cokpit_radius(0.0f)
        return
      if vehicle_seats__seatEids[seatNo] == eid
        let hasHatch = seats_hatch_nodes__isValid
        let isHatchClosed = hasHatch && seats_hatch_nodes__openPos <= 0.f
        let currentRadius = (!hasHatch || isHatchClosed) ? effectsCulling__cockpitRadius : 0f
        set_cokpit_radius(currentRadius)

[es(on_disappear, tag=render, no_order, REQUIRE=hero)]
def control_effects_on_exit_es(evt : Event)
  set_cokpit_radius(0f)