require ecs
require ecs.safe
require app
require soundHash
require soundSystem
require soundEvent
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_physmat_common
require sound_utils_net.modules.sound_utils_net_events
require human_sounds.modules.human_sounds_events
require GridCollision
require CollisionTraces
require PhysMat
require Dacoll
require HumanPhys
require EnlistedHuman
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


def watch_step(cur_eid : EntityId; pos : float3; offset, max_len : float;
               var in_out_mat_id : int&; var out_water_depth : float&;
               human_net_phys : HumanActor)

  let from = float3(pos.x, pos.y + offset, pos.z)
  var len = max_len
  var matId = PHYSMAT_INVALID
  if !tracedown_normalized(from, len, matId, ETF_DEFAULT, human_net_phys.phys.traceHandle)
    len = max_len
    matId = PHYSMAT_INVALID

  trace_entities_in_grid(ecs_hash("vehicles"), from, float3(0., -1., 0.), len, cur_eid, SortIntersections NO) <| $(intersections : array<IntersectedEntity>#)
    for it in intersections
      if it.t < len + FLT_EPSILON
        len = it.t
        matId = PHYSMAT_INVALID
        query(it.eid) <| $ [es] (material : string)
          matId = get_material_id(material)
        if matId == PHYSMAT_INVALID
          matId = get_material_id("default")

  if matId != PHYSMAT_INVALID
    in_out_mat_id = matId

  out_water_depth = 0.
  var water = 0.
  if traceht_water(from, water) && pos.y < water
    let posXZ = pos.xz
    let ground = traceht_lmesh(posXZ)
    let floor = max(from.y - len, ground)
    out_water_depth = max(0., water - floor)



def play_footstep(desc : Object;
                  eid : EntityId;
                  transform : float3x4;
                  team : int;
                  right_step : bool;
                  is_watched_sound : bool;
                  path : Object;
                  tags : Object;
                  _traceStepOffsetLen : float2;
                  _friendVolume : float;
                  _biomePhysMatId : int;
                  _biomeOverridesWater : bool;
                  _puddleDepth : float;
                  var _matId : int&;
                  var _waterDepth : float&;
                  human_net_phys : HumanActor)
  let nodePos = transform[3]
  let volume = (!is_watched_sound && is_teams_friendly(team, (get_int(get_controlled_hero(), "team") ?? TEAM_UNASSIGNED))) ? _friendVolume : 1.

  if is_watched_sound || right_step
    watch_step(eid, nodePos, _traceStepOffsetLen.x, _traceStepOffsetLen.y, _matId, _waterDepth, human_net_phys)

  var pmid = PHYSMAT_INVALID
  let isOnLMesh = is_on_lmesh(transform[3])
  let waterDepth = isOnLMesh ? max(_waterDepth, _puddleDepth) : _waterDepth
  let isInWater = waterDepth > 0.
  if isOnLMesh && _biomePhysMatId != PHYSMAT_INVALID && (!isInWater || _biomeOverridesWater)
    pmid = _biomePhysMatId
  else
    pmid = isInWater ? get_material_id("water") : _matId;
  if pmid == PHYSMAT_INVALID
    return

  var pathStr : string
  if sound_player_common::get_option_path(path, tags, is_watched_sound, pathStr)
    var handle = sound_player_common::play_desc_path(desc, pathStr, nodePos, false)
    if _waterDepth > 0.
      set_var(handle, "depth", _waterDepth)
    if read_sound_tag("armored", tags)
      set_var(handle, "armored", 1.)
    set_volume(handle, volume)
    set_var(handle, "mat", get_sound_step_material_id(pmid))
    abandon(handle)


[es(tag=sound, REQUIRE=humanSound)]
def human_steps_sound_irq(evt : CmdSoundStepIrq;
                          var human_steps_sound__irqObjIdx : int&)
  if human_steps_sound__irqObjIdx < FIRST_VALID_IRQ_OBJ_IDX || is_right_step(evt.objIdx)
    human_steps_sound__irqObjIdx = evt.objIdx


[es(tag=sound, after=(human_step_sound_queries_es, start_async_phys_sim_es))] // after start_async_phys_sim_es to start phys sim job earlier
def human_steps_sound_irqs_update(info : ParallelUpdateFrameDelayed)

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
                     human_step_sound_queries__biomePhysMatId : int;
                     human_step_sound_queries__biomeOverridesWater : bool;
                     human_step_sound_queries__puddleDepth : float;
                     var human_steps_sound__matId : int&;
                     var human_steps_sound__waterDepth : float&;
                     human_steps_sound__farawayThresholdSq : float;
                     human_net_phys__states : int = int(StateFlag ST_ON_GROUND);
                     human_net_phys__isClimbing : bool = false;
                     human_net_phys : HumanActor)

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
                    human_step_sound_queries__biomePhysMatId,
                    human_step_sound_queries__biomeOverridesWater,
                    human_step_sound_queries__puddleDepth,
                    human_steps_sound__matId,
                    human_steps_sound__waterDepth,
                    human_net_phys)

    human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX

    let isRun = read_flag(StateFlag ST_SPRINT, human_net_phys__states) && !read_flag(StateFlag ST_WALK, human_net_phys__states)
    sound_player_common::play_path(isRun ? human_steps_sound__runVoiceFx : human_steps_sound__walkVoiceFx, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)



[es(tag=sound, after=(human_step_sound_queries_es, start_async_phys_sim_es))] // after start_async_phys_sim_es to start phys sim job earlier
def human_steps_sound_update(info : ParallelUpdateFrameDelayed)

  let listenerPos = get_listener_pos()

  query() <| $ [es] (eid : EntityId;
                     transform : float3x4;
                     team : int;
                     is_watched_sound : bool;
                     [[shared_comp]] human_steps_sound__path : Object;
                     [[shared_comp]] human_steps_sound__descs : Object;
                     [[shared_comp]] human_steps_sound__jumpFx : Object;
                     sound_tags : Object;
                     human_steps_sound__farawayThresholdSq : float;
                     human_steps_sound__traceStepOffsetLen : float2;
                     human_steps_sound__friendVolume : float;
                     human_step_sound_queries__biomePhysMatId : int;
                     human_step_sound_queries__biomeOverridesWater : bool;
                     human_step_sound_queries__puddleDepth : float;
                     human_net_phys__states : int;
                     human_net_phys__isClimbing : bool;
                     var human_steps_sound__matId : int&;
                     var human_steps_sound__waterDepth : float&;
                     var human_steps_sound__physStates : int&;
                     var human_steps_sound__lastTimeOnGround : float&;
                     human_net_phys : HumanActor)

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
      let threshold = 0.1
      if !human_net_phys__isClimbing && info.curTime > human_steps_sound__lastTimeOnGround + threshold
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

    if name != ""
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
                      human_step_sound_queries__biomePhysMatId,
                      human_step_sound_queries__biomeOverridesWater,
                      human_step_sound_queries__puddleDepth,
                      human_steps_sound__matId,
                      human_steps_sound__waterDepth,
                      human_net_phys)



[es(tag=sound, on_appear)]
def human_steps_sound_on_appear(evt : Event;
                                human_steps_sound__tag : string;
                                var sound_tags : Object&)
  raise_sound_tag(human_steps_sound__tag, sound_tags)
