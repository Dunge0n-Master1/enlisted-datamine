module human_parachute_common shared
require ecs
require Dacoll


def get_parachute_altitude(pos : float3)
  let posXZ = pos.xz
  var altitude = pos.y - traceht_lmesh(posXZ)

  var waterHeight = 0.0
  if traceht_water(pos, waterHeight)
    let waterAltitude = pos.y - waterHeight
    altitude = min(altitude, waterAltitude)

  return altitude

def parachute_create_for_eid(eid : EntityId; parachute_template : string)
  return createEntity(parachute_template) <| $(init)
    init |> set("item__ownerEid", eid)
    init |> set("skeleton_attach__attached", true)
    init |> set("slot_attach__attachedTo", eid)
    init |> set("skeleton_attach__attachedTo", eid)