require ecs
require soundEvent
require soundSystem
require math.base
require DagorMath
require Dacoll
require AnimV20
require GeomNodeTree
require DagorSystem


def advance(var values : float3&)
  values.z = values.y
  values.y = values.x
  values.x = 0.


def make_param(var values : float3&; max_value : float; t : float; num_rays : int)
  return saturate(safediv(lerp(values.z, values.y, t), float(num_rays) * max_value)) * 100.


def get_reverb_3d_pos()
  var pos = get_listener_pos()
  query() <| $ [es] (is_watched_sound : bool;
                     human_reverb_sound__nodeId : int;
                     animchar : AnimcharBaseComponent)
    if is_watched_sound && human_reverb_sound__nodeId >= 0
      pos = geomtree_getNodeWpos(*animchar.nodeTree, human_reverb_sound__nodeId) + float3(0., 0.1, 0.)
  return pos


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(animchar_render_es, start_async_phys_sim_es))] // after start_async_phys_sim_es to start phys sim job earlier
def reverb_sound_update(evt : Event;
                        var reverb_sound__rayId : int&;
                        var reverb_sound__intensityValues : float3&;
                        var reverb_sound__roomSizeValues : float3&;
                        reverb_sound__intensityMax : float;
                        reverb_sound__intensityVar : string;
                        reverb_sound__roomSizeMax : float;
                        reverb_sound__roomSizeVar : string;
                        reverb_sound__rays : Point3List;
                        reverb_sound__rayLength : float;
                        reverb_sound__fadeOutPower : float;
                        reverb_sound__event : SoundEvent&)
  let numRays = length(reverb_sound__rays)
  assert(uint(reverb_sound__rayId) < uint(numRays))
  let pos = get_reverb_3d_pos()
  let dir = reverb_sound__rays[reverb_sound__rayId]
  set_pos(reverb_sound__event.handle, pos)

  var norm : float3
  var t = reverb_sound__rayLength
  if traceray_normalized(pos, dir, t, norm)
    let distT = saturate(safediv(t, reverb_sound__rayLength))
    reverb_sound__intensityValues.x += saturate(-dot(norm, dir)) * (1. - pow(distT, reverb_sound__fadeOutPower))
    reverb_sound__roomSizeValues.x += t
  else
    reverb_sound__roomSizeValues.x += reverb_sound__rayLength

  ++reverb_sound__rayId
  if reverb_sound__rayId >= numRays
    advance(reverb_sound__intensityValues)
    advance(reverb_sound__roomSizeValues)
    reverb_sound__rayId = 0

  t = safediv(float(reverb_sound__rayId), float(numRays))
  let intensity = make_param(reverb_sound__intensityValues, reverb_sound__intensityMax, t, numRays)
  set_var_global(reverb_sound__intensityVar, intensity)
  let roomSize = make_param(reverb_sound__roomSizeValues, reverb_sound__roomSizeMax, t, numRays)
  set_var(reverb_sound__event.handle, reverb_sound__roomSizeVar, roomSize)


[es(tag=sound, on_appear)]
def reverb_sound_appear(evt : Event;
                        reverb_sound__path : string;
                        reverb_sound__intensityVar : string;
                        var reverb_sound__event : SoundEvent&)
  // master banks containing 'reverb_sound__path' event should be already loaded at this point!
  // so master banks should be configurated as "async:b=no".
  // or may track 'sound_bank_preset_state__isValid' to wait and start when all banks are loaded.
  reverb_sound__event |> play(reverb_sound__path, get_reverb_3d_pos())
  set_var_global(reverb_sound__intensityVar, 0.)


[es(tag=sound, on_disappear)]
def reverb_sound_destroyed(evt : Event;
                           reverb_sound__intensityVar : string;
                           var reverb_sound__event : SoundEvent&)

  release(reverb_sound__event.handle)
  set_var_global(reverb_sound__intensityVar, 0.)


[es(tag=sound, on_appear)]
def human_reverb_sound_init_node_id(evt : Event;
                                    animchar : AnimcharBaseComponent;
                                    human_animchar_sound__reverbNode : string;
                                    var human_reverb_sound__nodeId : int&)
  if human_animchar_sound__reverbNode != ""
    human_reverb_sound__nodeId = geomtree_findNodeIndex(*animchar.nodeTree, human_animchar_sound__reverbNode)
    if human_reverb_sound__nodeId == -1
      logerr("Reverb node '{human_animchar_sound__reverbNode}' not found")

