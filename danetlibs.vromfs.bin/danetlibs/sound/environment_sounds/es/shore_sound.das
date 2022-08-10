require ecs
require app
require math.base
require DagorMath
require DagorDebug3D
require soundEvent
require soundSystem

[es(no_order, tag=(render, sound), REQUIRE=soundDebugDrawEnable)]
def shore_sound_debug_draw(info : UpdateStageInfoRenderDebug;
                           shore_sound__offsets : Point2List;
                           transform : float3x4)
  for idx in range(length(shore_sound__offsets) - 1)
    draw_debug_line_buffered(transform * float3(shore_sound__offsets[idx].x, 0., shore_sound__offsets[idx].y),
                             transform * float3(shore_sound__offsets[idx + 1].x, 0., shore_sound__offsets[idx + 1].y),
                             E3DCOLOR(0xffffffff), 2)
  if length(shore_sound__offsets) >= 2
    draw_debug_line_buffered(transform * float3(shore_sound__offsets[0].x, 0., shore_sound__offsets[0].y),
                             transform * float3(shore_sound__offsets[length(shore_sound__offsets) - 1].x, 0., shore_sound__offsets[length(shore_sound__offsets) - 1].y),
                             E3DCOLOR(0xff8000ff), 2)


[es(tag=sound, after=birds_sound_update)]
def shore_sound_update(info : UpdateStageInfoAct;
                       sound_bank_preset_state__isValid : bool;
                       shore_sound__event : SoundEvent&;
                       shore_sound__offsets : Point2List;
                       transform : float3x4)
  if sound_bank_preset_state__isValid && length(shore_sound__offsets) >= 2
    let listener = inverse(transform) * soundSystem::get_listener_pos()
    var idx = 0
    while idx < length(shore_sound__offsets) - 2 && listener.x >= shore_sound__offsets[idx + 1].x
      ++idx
    let a = shore_sound__offsets[idx]
    let b = shore_sound__offsets[idx + 1]
    let t = safediv(listener.x - a.x, b.x - a.x);
    let pos = transform * float3(listener.x, 0., max(lerp(a.y, b.y, t), listener.z))
    set_pos(shore_sound__event.handle, pos)


[es(tag=sound, track=sound_bank_preset_state__isValid, on_event=EventComponentChanged)]
def shore_sound_toggle(evt : Event;
                       sound_bank_preset_state__isValid : bool;
                       shore_sound__path : string;
                       var shore_sound__event : SoundEvent&)
  release_immediate(shore_sound__event.handle)
  if sound_bank_preset_state__isValid
    shore_sound__event |> play(shore_sound__path)
