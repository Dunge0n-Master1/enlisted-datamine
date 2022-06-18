require ecs
require soundHash
require game.es.sound.sound_events
require sound_utils.modules.sound_utils_events

[es(tag=sound, REQUIRE=net_sound__descs)]
def tinnituss_sound(evt : CmdStartTinnitussSfx;
                    eid : EntityId)
  sendEvent(eid, [[CmdPlaySound hash=sound_hash("tinnituss"), pos=evt.pos, param=evt.power]])
