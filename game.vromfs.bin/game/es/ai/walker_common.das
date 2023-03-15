module walker_common shared

require DagorRandom
require DagorMath
require math.base
require pathfinder
require math.maybe_pos
require ecs
require HumanPhys

let
  STANCE_STAND = 2
  STANCE_CROUCH = 1
  STANCE_CRAWL = 0


def determinate_stance(phys_state : HumanPhysState)
  if phys_state.isCrawl
    return STANCE_CRAWL
  if phys_state.isCrouch
    return STANCE_CROUCH
  return STANCE_STAND


def danger_area_update(var agentDangerAreas : ecs::Object;
                       area_name : string;
                       tm : float3x4;
                       oobb : BBox3)
  using() <| $(var obj : Object)
    set(obj, "itm", inverse(tm))
    set(obj, "oobbMin", oobb.boxMin)
    set(obj, "oobbMax", oobb.boxMax)
    set(agentDangerAreas, area_name, obj)


def danger_areas_test_point(agentDangerAreas : ecs::Object; pt : float3)
  for it in agentDangerAreas
    let obj = get_ecs_object(it.value)
    if obj == null
      continue
    let itm = get_TMatrix(*obj, "itm") ?? float3x4()
    let oobbMin = get_Point3(*obj, "oobbMin") ?? float3(0.0f, 0.0f, 0.0f)
    let oobbMax = get_Point3(*obj, "oobbMax") ?? float3(0.0f, 0.0f, 0.0f)
    if BBox3(oobbMin, oobbMax) & (itm * pt)
      return true
  return false
