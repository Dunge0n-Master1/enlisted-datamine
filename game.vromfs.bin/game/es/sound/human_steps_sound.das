require ecs
require ecs.safe
require app
require soundHash
require soundSystem
require soundEvent
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_physmat_common
require sound_utils_net.modules.sound_utils_net_events
require common_sounds.modules.common_sounds_events
require GridCollision
require CollisionTraces
require PhysMat
require Dacoll
require HumanPhys
require DngHuman
require math
require math.base
require game.utils.hero
require game.utils.team
require DagorSystem


let INVALID_IRQ_OBJ_IDX = -1
let FIRST_VALID_IRQ_OBJ_IDX = 0


def is_faraway(is_watched : bool; pos : float3; max_distance_sq : float; listener_pos : float3)
  return !is_watched && length_sq(listener_pos - pos) > max_distance_sq

def read_flag(state_flag : StateFlag; states : int)
  return (states & int(state_flag)) != 0

def is_right_step(irq_obj_idx : int)
  return (irq_obj_idx & 1) != 0

def is_on_lmesh(pos : float3)
  let posXZ = pos.xz
  let ground = traceht_lmesh(posXZ)
  return pos.y < ground + 0.05


def play_footstep(desc : Object;
                  human_eid : EntityId;
                  transform : float3x4;
                  team : int;
                  right_step : bool;
                  is_watched_sound : bool;
                  path : Object;
                  sound_tags : Object;
                  human_steps_sound__traceStepOffsetLen : float2;
                  human_steps_sound__friendVolume : float;
                  sound_landmesh_queries__biomePhysMatId : int;
                  sound_landmesh_queries__biomeOverridesWater : bool;
                  sound_landmesh_queries__puddleDepth : float;
                  var human_steps_sound__smid : float&;
                  var human_steps_sound__waterDepth : float&;
                  var human_net_phys : HumanActor)
  let pos = transform[3]
  let volume = (!is_watched_sound && is_teams_friendly(team, (get_int(get_controlled_hero(), "team") ?? TEAM_UNASSIGNED))) ? human_steps_sound__friendVolume : 1.

  var pmid = PHYSMAT_INVALID
  if is_watched_sound || right_step

    assume offset = human_steps_sound__traceStepOffsetLen.x
    assume maxLen = human_steps_sound__traceStepOffsetLen.y

    let from = float3(pos.x, pos.y + offset, pos.z)
    var len = maxLen
    if !tracedown_normalized(from, len, pmid, ETF_DEFAULT, human_net_phys.phys |> human_phys_getTraceHandle())
      len = maxLen
      pmid = PHYSMAT_INVALID

    trace_entities_in_grid(ecs_hash("vehicles"), from, float3(0., -1., 0.), len, human_eid, SortIntersections NO) <| $(intersections : array<IntersectedEntity>#)
      for it in intersections
        if it.t < len + FLT_EPSILON
          len = it.t
          pmid = PHYSMAT_INVALID
          query(it.eid) <| $ [es] (material : string)
            pmid = get_material_id(material)
          if pmid == PHYSMAT_INVALID
            pmid = get_material_id("default")

    human_steps_sound__waterDepth = 0.
    var water = 0.
    if traceht_water(from, water) && pos.y < water
      let posXZ = pos.xz
      let ground = traceht_lmesh(posXZ)
      let floor = max(from.y - len, ground)
      human_steps_sound__waterDepth = max(0., water - floor)


  let isOnLMesh = is_on_lmesh(transform[3])
  let waterDepth = isOnLMesh ? max(human_steps_sound__waterDepth, sound_landmesh_queries__puddleDepth) : human_steps_sound__waterDepth
  let isInWater = waterDepth > 0.
  if isOnLMesh && sound_landmesh_queries__biomePhysMatId != PHYSMAT_INVALID && (!isInWater || sound_landmesh_queries__biomeOverridesWater)
    pmid = sound_landmesh_queries__biomePhysMatId
  elif isInWater
    pmid = get_material_id("water")

  if pmid != PHYSMAT_INVALID
    human_steps_sound__smid = get_sound_step_material_id(pmid)

  if human_steps_sound__smid >= 0.
    var pathStr : string
    if sound_player_common::get_option_path(path, sound_tags, is_watched_sound, pathStr)
      var handle = sound_player_common::play_desc_path(desc, pathStr, pos, false)
      if human_steps_sound__waterDepth > 0.
        set_var(handle, "depth", human_steps_sound__waterDepth)
      if read_sound_tag("armored", sound_tags)
        set_var(handle, "armored", 1.)
      set_volume(handle, volume)
      set_var(handle, "mat", human_steps_sound__smid)
      abandon(handle)


[es(tag=sound, REQUIRE=humanSound)]
def human_steps_sound_irq(evt : CmdSoundStepIrq;
                          var human_steps_sound__irqObjIdx : int&)
  if human_steps_sound__irqObjIdx < FIRST_VALID_IRQ_OBJ_IDX || is_right_step(evt.objIdx)
    human_steps_sound__irqObjIdx = evt.objIdx


[es(tag=sound, after=(sound_landmesh_queries_update, start_async_phys_sim_es))] // after start_async_phys_sim_es to start phys sim job earlier
def human_steps_sound_update(info : ParallelUpdateFrameDelayed)

  let listenerPos = get_listener_pos()

  query() <| $ [es] (eid : EntityId;
                     transform : float3x4;
                     team : int;
                     is_watched_sound : bool;
                     [[shared_comp]] human_steps_sound__path : Object;
                     [[shared_comp]] human_steps_sound__irqs : Array;
                     var human_steps_sound__irqObjIdx : int&;
                     [[shared_comp]] human_steps_sound__runVoiceFx : Object;
                     [[shared_comp]] human_steps_sound__walkVoiceFx : Object;
                     sound_tags : Object;
                     var sound_event_group : SoundEventGroup&;
                     human_steps_sound__traceStepOffsetLen : float2;
                     human_steps_sound__friendVolume : float;
                     sound_landmesh_queries__biomePhysMatId : int;
                     sound_landmesh_queries__biomeOverridesWater : bool;
                     sound_landmesh_queries__puddleDepth : float;
                     var human_steps_sound__smid : float&;
                     var human_steps_sound__waterDepth : float&;
                     human_steps_sound__farawayThresholdSq : float;
                     human_net_phys__states : int = int(StateFlag ST_ON_GROUND);
                     human_net_phys__isClimbing : bool = false;
                     var human_net_phys : HumanActor)

    if human_steps_sound__irqObjIdx < FIRST_VALID_IRQ_OBJ_IDX
      return

    if is_faraway(is_watched_sound, transform[3], human_steps_sound__farawayThresholdSq, listenerPos)
      human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX
      return

    if !read_flag(StateFlag ST_ON_GROUND, human_net_phys__states) || human_net_phys__isClimbing
      human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX
      return

    let desc = human_steps_sound__irqs?[human_steps_sound__irqObjIdx] ?as Object
    if desc != null
      play_footstep(*desc,
                    eid,
                    transform,
                    team,
                    is_right_step(human_steps_sound__irqObjIdx),
                    is_watched_sound,
                    human_steps_sound__path,
                    sound_tags,
                    human_steps_sound__traceStepOffsetLen,
                    human_steps_sound__friendVolume,
                    sound_landmesh_queries__biomePhysMatId,
                    sound_landmesh_queries__biomeOverridesWater,
                    sound_landmesh_queries__puddleDepth,
                    human_steps_sound__smid,
                    human_steps_sound__waterDepth,
                    human_net_phys)

    human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX

    let isRun = read_flag(StateFlag ST_SPRINT, human_net_phys__states) && !read_flag(StateFlag ST_WALK, human_net_phys__states)
    sound_player_common::play_path(isRun ? human_steps_sound__runVoiceFx : human_steps_sound__walkVoiceFx, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)


  query() <| $ [es] (eid : EntityId;
                     transform : float3x4;
                     team : int;
                     is_watched_sound : bool;
                     [[shared_comp]] human_steps_sound__path : Object;
                     [[shared_comp]] human_steps_sound__descs : Object;
                     [[shared_comp]] human_steps_sound__jumpFx : Object;
                     [[shared_comp]] sound_paths : Object;
                     sound_tags : Object;
                     human_steps_sound__farawayThresholdSq : float;
                     human_steps_sound__traceStepOffsetLen : float2;
                     human_steps_sound__friendVolume : float;
                     human_steps_sound__fallSpeedCollThreshold : float;

                     sound_landmesh_queries__biomePhysMatId : int;
                     sound_landmesh_queries__biomeOverridesWater : bool;
                     sound_landmesh_queries__puddleDepth : float;

                     human_net_phys__states : int;
                     human_net_phys__isClimbing : bool;

                     var sound_landmesh_queries_vars__speedSq : float&;
                     var sound_landmesh_queries_vars__isOnGround : bool&;

                     var human_steps_sound__smid : float&;
                     var human_steps_sound__waterDepth : float&;
                     var human_steps_sound__physStates : int&;
                     var human_steps_sound__lastTimeOnGround : float&;
                     var human_net_phys : HumanActor)

    sound_landmesh_queries_vars__speedSq = length_sq(human_net_phys.phys.currentState.velocity.xz)
    sound_landmesh_queries_vars__isOnGround = read_flag(StateFlag ST_ON_GROUND, human_net_phys__states)

    if human_steps_sound__physStates < 0
      human_steps_sound__physStates = human_net_phys__states

    let raisedStates = human_net_phys__states & ~human_steps_sound__physStates
    let clearedStates = human_steps_sound__physStates & ~human_net_phys__states
    human_steps_sound__physStates = human_net_phys__states

    if read_flag(StateFlag ST_ON_GROUND, clearedStates)
      human_steps_sound__lastTimeOnGround = info.curTime

    if is_faraway(is_watched_sound, transform[3], human_steps_sound__farawayThresholdSq, listenerPos)
      return

    if (raisedStates | clearedStates) == 0
      return

    var name = ""
    if read_flag(StateFlag ST_JUMP, raisedStates)
      name = "jump"
      sound_player_common::play_path(human_steps_sound__jumpFx, sound_tags, is_watched_sound, transform[3])
    elif read_flag(StateFlag ST_ON_GROUND, raisedStates)
      let lastTimeOnGroundThreshold = 0.1
      if !human_net_phys__isClimbing && info.curTime > human_steps_sound__lastTimeOnGround + lastTimeOnGroundThreshold

        let speed = -min(human_net_phys.phys.currentState.velocity.y, human_net_phys.phys.previousState.velocity.y)
        if speed >= human_steps_sound__fallSpeedCollThreshold
          play_path("collision_fall", sound_paths, sound_tags, is_watched_sound, transform[3])
          return

        name = "land"
    elif read_flag(StateFlag ST_SWIM, raisedStates)
      if !read_flag(StateFlag ST_ON_GROUND, human_net_phys__states)
        name = "land"
    elif read_flag(StateFlag ST_CROUCH, raisedStates)
      name = "downKnee"
    elif read_flag(StateFlag ST_CROUCH, clearedStates)
      name = "upKnee"
    elif read_flag(StateFlag ST_DOWNED, raisedStates)
      name = "downKnee"
    elif read_flag(StateFlag ST_DOWNED, clearedStates)
      name = "upKnee"
    elif read_flag(StateFlag ST_CRAWL, raisedStates)
      name = "downGround"
    elif read_flag(StateFlag ST_CRAWL, clearedStates)
      name = "upGround"

    if !empty(name)
      let desc = sound_player_common::get_desc(human_steps_sound__descs, name)
      if desc != null
        play_footstep(*desc,
                      eid,
                      transform,
                      team,
                      false,
                      is_watched_sound,
                      human_steps_sound__path,
                      sound_tags,
                      human_steps_sound__traceStepOffsetLen,
                      human_steps_sound__friendVolume,
                      sound_landmesh_queries__biomePhysMatId,
                      sound_landmesh_queries__biomeOverridesWater,
                      sound_landmesh_queries__puddleDepth,
                      human_steps_sound__smid,
                      human_steps_sound__waterDepth,
                      human_net_phys)



[es(tag=sound, on_appear)]
def human_steps_sound_on_appear(evt : Event;
                                human_steps_sound__tag : string;
                                var sound_tags : Object&)
  raise_sound_tag(human_steps_sound__tag, sound_tags)
