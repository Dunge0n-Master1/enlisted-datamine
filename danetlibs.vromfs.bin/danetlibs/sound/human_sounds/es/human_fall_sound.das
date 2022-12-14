require ecs


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=human_sound_es, REQUIRE_NOT=human_spawn_sound__inSpawn)]
def human_fall_sound_is_falling_update(evt : Event;
                                       human_net_phys__isUnderwater : bool;
                                       human_net_phys__deltaVelIgnoreAmount : float;
                                       human_net_phys__velocity : float3 const&;
                                       human_fall_sound__threshold : float;
                                       var human_fall_sound__isFalling : bool&)
  human_fall_sound__isFalling = (human_net_phys__velocity.y < -human_fall_sound__threshold &&
                                 !human_net_phys__isUnderwater &&
                                 human_net_phys__deltaVelIgnoreAmount <= 0.)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=human_sound_es)]
def human_fall_sound_with_spawn_is_falling_update(evt : Event;
                                                  human_net_phys__isUnderwater : bool;
                                                  human_net_phys__deltaVelIgnoreAmount : float;
                                                  human_net_phys__velocity : float3 const&;
                                                  human_fall_sound__threshold : float;
                                                  human_spawn_sound__inSpawn : bool;
                                                  var human_fall_sound__isFalling : bool&)
  human_fall_sound__isFalling = (human_net_phys__velocity.y < -human_fall_sound__threshold &&
                                 !human_spawn_sound__inSpawn &&
                                 !human_net_phys__isUnderwater &&
                                 human_net_phys__deltaVelIgnoreAmount <= 0.)
