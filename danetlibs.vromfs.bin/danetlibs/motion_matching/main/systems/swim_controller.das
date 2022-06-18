require ecs
require math.base
require strings
require DagorMath
require DagorSystem
require daslib/strings_boost

def index(var tags : StringList; tag : string) : int
  return find_index_if(each(tags)) <| $(s) { return eq(s, tag); }

def has(var tags : StringList; tag : string) : bool
  return index(tags, tag) != -1

def add_tag(var tags : StringList; tag : string)
  if !has(tags, tag)
    tags |> push(tag)

def remove_tag(var tags : StringList; tag : string)
  let idx = index(tags, tag)
  if idx != -1
    tags |> erase(idx)

[es(tag=gameClient, track=human_net_phys__isSwimming)]
def motion_matching_watch_swim(event : Event;
                               var goal_tags : StringList;
                               human_net_phys__isSwimming : bool;
                               var motion_matching_enabled : bool&)

  motion_matching_enabled = human_net_phys__isSwimming
  if human_net_phys__isSwimming
    add_tag(goal_tags, "swim")
  else
    remove_tag(goal_tags, "swim")



[es(tag=gameClient, no_order)]
def update_mm_trajectory(act : UpdateStageInfoAct;
                         transform : float3x4;
                         var goal_tags : StringList;
                         var prev_tranform : float3x4&;
                         var input_linear_velocity, input_angular_velocity : float3&;
                         human_net_phys__velocity : float3;
                         motion_matching_enabled : bool)
  if motion_matching_enabled
    var instantOmega : float3
    let quaternion = inverse(quat(prev_tranform)) * quat(transform)
    quat_to_euler(quaternion, instantOmega.x, instantOmega.y, instantOmega.z)
    input_linear_velocity = rotate(inverse(transform), human_net_phys__velocity)
    input_angular_velocity = float3(0.0, instantOmega.x / act.dt, 0.0)
    if length(input_linear_velocity) < 0.1
      add_tag(goal_tags, "idle")
    else
      remove_tag(goal_tags, "idle")
    prev_tranform = transform
