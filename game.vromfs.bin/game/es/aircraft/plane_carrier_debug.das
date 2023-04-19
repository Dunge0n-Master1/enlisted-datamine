options no_aot
require ecs
require math.base
require DngPlane
require ecs.ecs_template
require DagorConsole
require DagorDebug3D

[ecs_template]
struct debug_carrier_template
  aircraftCarrierDebug : Tag

[es(REQUIRE=aircraftCarrierDebug, no_order)]
def draw_debug_carrier(info : UpdateStageInfoAct; inverseTransform : float3x4; transform aka zone_transform : float3x4)
  let box = BBox3(-float3(0.5), float3(0.5))
  draw_debug_box_buffered(box, zone_transform, E3DCOLOR(0xFF00FF00), 1)
  query() <| $ [es(REQUIRE=airplane)] (transform : float3x4)
    if IDENT_BBOX & (inverseTransform * transform[3])
      draw_debug_sphere_buffered(transform[3], 3.0, E3DCOLOR(0xFF0000FF), 1)

[console_cmd(name="carrier.draw_landing_zones", hint="Draw aircraft carrier landing zones and plane position")]
def set_aircraft_carrier_debug(activate : bool = true)
  if activate
    query() <| $ [es(REQUIRE=aircraftCarrierLandingZone, REQUIRE_NOT=aircraftCarrierDebug)] (eid : EntityId)
      addSubTemplate(eid, "debug_carrier_template")
  else
    query() <| $ [es(REQUIRE=aircraftCarrierDebug)] (eid : EntityId)
      removeSubTemplate(eid, "debug_carrier_template")
