require ecs
require enlisted.events_enlisted
require math.base
require DngCamera

[es(tag=gameClient)]
def create_charred_area_decal(evt : CmdSpawnCharredArea;
                              charred_area_decals_total_time : float;
                              charred_area_decals_max_cam_distsq : float;
                              charred_area_decals_max_count : int)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTm == null
    return

  let pos = evt.pos
  let normal = evt.normal
  let camPos = (*camTm)[3]
  if length_sq(camPos - pos) > charred_area_decals_max_cam_distsq
    return

  var decalsFound = 0
  var oldestDecal = INVALID_ENTITY_ID
  var oldestDecalLifeTime = charred_area_decals_total_time;
  let skipCreation = find_query() <| $ [es] (eid : EntityId;
                                             transform : float3x4;
                                             charred_area_radius : float;
                                             charred_area_left_time : float)
    decalsFound++
    if charred_area_left_time < oldestDecalLifeTime
      oldestDecalLifeTime = charred_area_left_time
      oldestDecal = eid

    if decalsFound >= charred_area_decals_max_count
      destroyEntity(oldestDecal)
      return true

    let dist2 = length_sq(transform[3] - pos)
    return dist2 < charred_area_radius * charred_area_radius * 0.25

  if skipCreation
    return

  var tm = IDENT_TM
  tm[3] = pos
  tm[1] = normal
  if abs(normal.y) < abs(normal.z)
    tm[2] = normalize(cross(normal, float3(0, 1, 0)))
  else
    tm[2] = normalize(cross(normal, float3(0, 0, 1)))
  tm[0] = normalize(cross(tm[1], tm[2]))
  createEntity("charred_area_decal") <| $(init)
    set(init, "transform", tm)