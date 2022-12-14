require ecs
require sound_utils.modules.sound_player_common
require soundSystem
require common_shooter.events_common_shooter
require EnlistedDm

[es(tag=sound, REQUIRE=(humanSound, watchedByPlr))]
def head_shot_kill_sound(evt : EventHeadShotKill;
                         [[shared_comp]] human_hit_sound__paths : Object;
                         sound_tags : Object;
                         human_hit_sound__headshotSoundEnabled : bool)
  if human_hit_sound__headshotSoundEnabled
    sound_player_common::play_path("heroHitEnemyHead", human_hit_sound__paths, sound_tags, true/*is_watched_sound*/, get_listener_pos())
