require ecs
require game.utils.hero
require soundEvent
require soundSystem
require enlisted.events_enlisted

[es(tag=sound, on_appear)]
def game_effect_sound_appear(evt : Event;
                             game_effect_sound__hero : string;
                             game_effect_sound__enemy : string;
                             var game_effect_sound__event : SoundEvent&;
                             game_effect__attachedTo : EntityId)
  abandon(game_effect_sound__event.handle)
  let sound = has(game_effect__attachedTo, "hero") ? game_effect_sound__hero : game_effect_sound__enemy
  if sound != ""
    ecs::query(game_effect__attachedTo) <| $ [es] (transform : float3x4)
      game_effect_sound__event |> play(sound, transform[3])
      game_effect_sound__event.abandonOnReset = true
      if is_oneshot(game_effect_sound__event.handle)
        abandon(game_effect_sound__event.handle)

[es(tag=sound, no_order)]
def game_effect_sound_update(info : ParallelUpdateFrameDelayed;
                             game_effect_sound__event : SoundEvent&;
                             game_effect__attachedTo : EntityId)
  if is_valid(game_effect_sound__event.handle)
    ecs::query(game_effect__attachedTo) <| $ [es] (transform : float3x4)
      set_pos(game_effect_sound__event.handle, transform[3])
