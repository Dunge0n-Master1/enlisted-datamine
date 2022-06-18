require ecs
require ecs.common
require app
require EnlistedNet
require soundHash
require game.es.events
require game.es.sound_net.sound_net_events
require game.utils.net_utils
require game.utils.sound_utils

[es(tag=server, REQUIRE=net_sound__riextraDestroyed)]
def ri_net_sound_on_riextra_destroyed(evt : EventRiExtraDestroyed;
                                      eid : EntityId)
  play_net_sound_simple(eid, "riextraDestroyed", false/*should_exist*/)
