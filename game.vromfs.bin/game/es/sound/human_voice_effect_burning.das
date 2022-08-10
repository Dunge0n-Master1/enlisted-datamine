require ecs

[es(tag=sound, track=burning__isBurning)]
def human_voice_effect_burning(evt : Event;
                               burning__isBurning : bool;
                               var human_voice_effect__activeEffects : Object&)
  human_voice_effect__activeEffects |> set("burn", burning__isBurning)
