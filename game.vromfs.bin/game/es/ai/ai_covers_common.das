module ai_covers_common shared

require app
require ecs
require math
require math.base
require math.random
require pathfinder
require Dacoll
require enlisted.game.es.ai.walker_common


struct FilterCoversInfo
  waterLevel : float
  waterWalkH : float

def get_filter_covers_info()
  var waterLevel = 0.0
  var waterWalkH = 0.1
  query() <| $ [es] (water__level : float;
                     water__smallWaterAIWalkHeight : float = 0.1)
    waterLevel = water__level
    waterWalkH = water__smallWaterAIWalkHeight
  return [[FilterCoversInfo waterLevel=waterLevel, waterWalkH=waterWalkH]]


def filter_cover(cover : Cover; var cover_desc : CoverDesc&; bbox, max_occupied, filter_info)
  if cover_desc.numUsedSlots >= length(cover_desc.slots)
    return true
  if max_occupied >= 0 && cover_desc.numUsedSlots > max_occupied
    return true

  let coverSideThreshold = 0.1
  let heightDiff = abs(cover.groundLeft.y - cover.groundRight.y)
  let groundLen = max(1.0, length_sq(cover.groundLeft - cover.groundRight))
  if heightDiff / groundLen > coverSideThreshold
    return true

  let minH = min(cover.groundLeft.y, cover.groundRight.y)
  if minH > bbox.bmax.xyz.y
    return true
  let maxH = max(cover.groundLeft.y + cover.hLeft, cover.groundRight.y + cover.hRight)
  if maxH < bbox.bmin.xyz.y
    return true

  if cover_desc.forWaterLevel != filter_info.waterLevel
    cover_desc.forWaterLevel = filter_info.waterLevel
    let groundMid = (cover.groundLeft + cover.groundRight) * 0.5
    var result = false
    traceht_water_at_time(groundMid + float3(0.0, filter_info.waterWalkH, 0.0), 0.0f, get_sync_time(), result)
    cover_desc.isUnderwater = result
  if cover_desc.isUnderwater
    return true

  return false

def get_cover_slot_pos(cover, cover_desc, slot_idx)
  let wallOffset = 0.25
  return cover_desc.slots[slot_idx].pos - cover.dir * wallOffset

def get_cover_walkout_pos(cover, side)
  let shootWallOffset = 0.35
  if side < 0
    return cover.shootLeft - cover.dir * shootWallOffset
  return cover.shootRight - cover.dir * shootWallOffset

def check_cover_pos_valid(pos)
  var newPos = pos
  if !project_to_nearest_navmesh_point(newPos, 0.5)
    return false
  let maxOffDistSq = square(0.3)
  if distance_sq(newPos, pos) > maxOffDistSq
    return false
  if abs(newPos.y - pos.y) > 0.3
    return false
  return true


enum CoverAttackType
  NONE            = 0
  CROUCH_TO_STAND = 1
  CRAWL_TO_CROUCH = 2
  CRAWL_TO_STAND  = 3
  WALKOUT_LEFT    = 4
  WALKOUT_RIGHT   = 5
  PRONE_DOWN      = 6
  STAND_STRAFES   = 7
  COUNT           = 8

let cover_attk_max_stances = [[int[8] 2; 2; 1; 2; 2; 2; 1; 2]]
let cover_attk_min_stances = [[int[8] 1; 2; 1; 2; 1; 1; 1; 1]]
let cover_hide_max_stances = [[int[8] 2; 1; 0; 0; 2; 2; 1; 2]]
let cover_hide_min_stances = [[int[8] 1; 1; 0; 0; 1; 1; 1; 1]]

def get_cover_attack_stance(attack_type)
  let idx = int(attack_type)
  if idx >= 0 && idx < int(CoverAttackType COUNT)
    return rnd_int(0, 100) < 50 ? cover_attk_max_stances[idx] : cover_attk_min_stances[idx]
  return STANCE_STAND

def get_cover_hide_stance(attack_type)
  let idx = int(attack_type)
  if idx >= 0 && idx < int(CoverAttackType COUNT)
    return rnd_int(0, 100) < 50 ? cover_hide_max_stances[idx] : cover_hide_min_stances[idx]
  return STANCE_CROUCH

def check_cover_attack(attack_type, cover, cover_slot_pos, walker_agent, target_pos)
  let attackStance = get_cover_attack_stance(attack_type)
  let heightUp = walker_agent.shootFrom[attackStance] - walker_agent.pos

  var attackPos = cover_slot_pos + heightUp
  if attack_type == CoverAttackType WALKOUT_LEFT
    attackPos = get_cover_walkout_pos(cover, -1) + heightUp
  elif attack_type == CoverAttackType WALKOUT_RIGHT
    attackPos = get_cover_walkout_pos(cover, 1) + heightUp

  let ofs = target_pos - attackPos
  let dir = normalize(ofs)
  let maxDist = 8.0
  let maxDistSq = square(maxDist)
  var dist = length_sq(ofs) > maxDistSq ? maxDist : length(ofs)
  var norm : float3
  return dist < VERY_SMALL_NUMBER || !traceray_normalized(attackPos, dir, dist, norm, ETF_ALL)

def check_cover_safe(cover_slot_pos, target_pos)
  let heightUp = float3(0.0, 0.6, 0.0)
  let hidePos = cover_slot_pos + heightUp

  let ofs = target_pos - hidePos
  let dir = normalize(ofs)
  var dist = length(ofs)
  var norm : float3
  return dist > VERY_SMALL_NUMBER && traceray_normalized(hidePos, dir, dist, norm, ETF_ALL)

def check_move_to_cover_along_fire_line(fromPos, toPos, enemyPos)
  let dir1 = normalize(enemyPos - fromPos)
  let dir2 = normalize(toPos - fromPos)
  return abs(dot(dir1, dir2)) > 0.95

def check_cover_near_enemies(pos, radius, agent_eid)
  var result = false
  let radiusSq = square(radius)
  let radiusOut = radius * 3.0
  let heightUp = 0.6
  let heightMax = pos.y + heightUp + 1.5
  let heightMin = pos.y + heightUp - 1.0
  let xzPos = float3(pos.x, 0.0, pos.z)
  query(agent_eid) <| $ [es] (agent_dangers : AgentDangers)
    for danger in agent_dangers.dangers
      if danger.distance > radiusOut
        continue
      query(danger.eid) <| $ [es] (transform : float3x4)
        let dangerPos = transform[3]
        if dangerPos.y > heightMin && dangerPos.y < heightMax
          if distance_sq(float3(dangerPos.x, 0.0, dangerPos.z), xzPos) < radiusSq
            result = true
      if result
        break
  return result


def eval_cover_attack_type_and_score(cover, desc, slot; var out_type : CoverAttackType&)
  let numSlots = length(desc.slots)
  if desc.slots[slot].numUsed > 0
    out_type = CoverAttackType NONE
    return 0
  let isWalkoutCover = cover.hasLeftPos || cover.hasRightPos
  if cover.hLeft > 1.25 // STAND
    if isWalkoutCover
      if cover.hasLeftPos && slot == 0
        out_type = CoverAttackType WALKOUT_LEFT
        return 3
      if cover.hasRightPos && slot == numSlots - 1
        out_type = CoverAttackType WALKOUT_RIGHT
        return 3
    return 0
  let isHalfCover = !isWalkoutCover && cover.shootLeft != float3()
  if cover.hLeft > 0.50 // CROUCH
    if isHalfCover
      out_type = CoverAttackType CROUCH_TO_STAND
      return 3
    return 0
  if isHalfCover // CRAWL
    out_type = CoverAttackType CRAWL_TO_CROUCH // alt to CRAWL_TO_STAND if can't attack from crouch
    return 2
  out_type = CoverAttackType PRONE_DOWN // alt to STAND_STRAFES randomly if has enough space around
  return 1

def eval_cover_score_stay(cover, desc, slot)
  let numSlots = length(desc.slots)
  if desc.slots[slot].numUsed > 0
    return 0
  let freeEnough = desc.numUsedSlots < (numSlots + 1) / 2
  let isWalkoutCover = cover.hasLeftPos || cover.hasRightPos
  if cover.hLeft > 1.25 // STAND
    if isWalkoutCover
      if cover.hasLeftPos && slot == 0
        return 2 // less when not for attack
      if cover.hasRightPos && slot == numSlots - 1
        return 2 // less when not for attack
      if numSlots <= 2
        return 0
    return desc.numUsedSlots == 0 ? 3 : freeEnough ? 2 : 0
  let isHalfCover = !isWalkoutCover && cover.shootLeft != float3()
  if cover.hLeft > 0.50 // CROUCH
    if isHalfCover
      return 5 // always good
    return desc.numUsedSlots == 0 ? 3 : freeEnough ? 2 : 0
  if !isHalfCover // CRAWL
    return 1
  return freeEnough ? 4 : 3
