options no_aot
require ecs
require DagorDebug3D
require DagorConsole
require DagorSystem
require game.es.vehicle.vehicle_events
require enlisted.game.es.ai.ai_vehicle_convoy_common



[console_cmd(name="vehicle_convoy.spawn_vehicles", hint="Spawns all vehicle convoys at their start position")]
def spawn_convoy_vehicles_cmd()
  spawn_convoy_vehicles()


[console_cmd(name="vehicle_convoy.generate_path", hint="(Re)Generates navmesh path from initial points")]
def generate_navmesh_path_cmd()
  query() <| $ [es] (ai_vehicle_convoy__pathPoints : Array;
                     var ai_vehicle_convoy__navmeshPathPoints : Point3List&;
                     var ai_vehicle_convoy__finalPointsByCapzoneGroup : Object&)
    generate_navmesh_path(ai_vehicle_convoy__pathPoints,
                          ai_vehicle_convoy__navmeshPathPoints,
                          ai_vehicle_convoy__finalPointsByCapzoneGroup)


def private destroy_vehicle_in_list(vehicles : EidList; vehicle_id : int)
  let vehiclesAmount = length(vehicles)
  if vehicle_id < 1 || vehicle_id > vehiclesAmount
    logerr("There are only {vehiclesAmount} vehicles in convoy. Id should be 1...{vehiclesAmount}")
    return

  let vehicleEid = vehicles[vehicle_id - 1]
  sendEvent(vehicleEid, [[CmdExplosionFatal offender=INVALID_ENTITY_ID, gunPropsId=-1, shellId=-1]])


[console_cmd(name="vehicle_convoy.explode", hint="Explodes a vehicle with given position in a given convoy. If convoy eid not specified, in all convoys")]
def explode_convoy_vehicle(vehicle_id : int; convoy_eid = 0u)
  if convoy_eid == 0u
    query() <| $ [es] (ai_vehicle_convoy__vehicles : EidList)
      destroy_vehicle_in_list(ai_vehicle_convoy__vehicles, vehicle_id)
  else
    query(EntityId(convoy_eid)) <| $ [es] (ai_vehicle_convoy__vehicles : EidList)
      destroy_vehicle_in_list(ai_vehicle_convoy__vehicles, vehicle_id)


[console_cmd(name="vehicle_convoy.reset", hint="Resets vehicle convoys to their initial state")]
def reset_convoy()
  query() <| $ [es] (var ai_vehicle_convoy__vehicles : EidList&;
                     var ai_vehicle_convoy__reachedPointId : int&)
    for vehicleEid in ai_vehicle_convoy__vehicles
      destroyEntity(vehicleEid)
    clear(ai_vehicle_convoy__vehicles)
    ai_vehicle_convoy__reachedPointId = 1


[console_cmd(name="vehicle_convoy.debug_path")]
def vehicle_convoy_debug_path()
  query() <| $ [es(REQUIRE=ai_vehicle_convoy__navmeshPathPoints)] (eid : EntityId)
    if has(eid, "vehicleConvoyDebugPath")
      removeSubTemplate(eid, "vehicle_convoy_debug_path")
    else
      addSubTemplate(eid, "vehicle_convoy_debug_path")


[console_cmd(name="vehicle_convoy.debug_destinations")]
def vehicle_convoy_debug_destinations()
  query() <| $ [es(REQUIRE=ai_vehicle_convoy__navmeshPathPoints)] (eid : EntityId)
    if has(eid, "vehicleConvoyDebugDestinations")
      removeSubTemplate(eid, "vehicle_convoy_debug_destinations")
    else
      addSubTemplate(eid, "vehicle_convoy_debug_destinations")


[es(no_order, tag=(dev, render), REQUIRE=(vehicleConvoyDebugDestinations))]
def vehicle_convoy_draw_destinations(info : UpdateStageInfoRenderDebug)
  begin_draw_cached_debug_lines(true, true, false)
  query() <| $ [es(REQUIRE_NOT=deadEntity)] (transform : float3x4;
                                             ai_vehicle_driver__destination : float3)
    draw_cached_debug_sphere(ai_vehicle_driver__destination, 1.0f, E3DCOLOR(0xFFFF0000), 12)
    let from = transform[3] + float3(0.0, 0.5, 0.0)
    let to = ai_vehicle_driver__destination + float3(0.0, 0.5, 0.0)
    draw_cached_debug_line(from, to, E3DCOLOR(0xFFFF0000))

  end_draw_cached_debug_lines()


[es(no_order, tag=(dev, render), REQUIRE=(vehicleConvoyDebugPath))]
def vehicle_convoy_draw_path(info : UpdateStageInfoRenderDebug;
                             ai_vehicle_convoy__pathPoints : Array;
                             ai_vehicle_convoy__navmeshPathPoints : Point3List;
                             ai_vehicle_convoy__finalPointId : int;
                             ai_vehicle_convoy__vehicleLength : float)
  begin_draw_cached_debug_lines(true, true, false)
  for point in ai_vehicle_convoy__pathPoints
    let pointObj = point |> get_ecs_object()
    if pointObj == null
      continue

    let pos = *pointObj |> get_Point3("pos")
    if pos == null
      continue

    let color = *pointObj |> get_string("groupName", "") == "" ? E3DCOLOR(0xAAFFFF00) : E3DCOLOR(0xAA0000FF)
    draw_cached_debug_sphere(*pos, 1.0f, color, 12)

  for idx, point in iter_range(ai_vehicle_convoy__navmeshPathPoints), ai_vehicle_convoy__navmeshPathPoints
    let color = idx > ai_vehicle_convoy__finalPointId + 1 ? E3DCOLOR(0xFFFF8800) : E3DCOLOR(0xFF00FF33)
    draw_cached_debug_sphere(point, ai_vehicle_convoy__vehicleLength * 0.5f, color, 12)

  end_draw_cached_debug_lines()