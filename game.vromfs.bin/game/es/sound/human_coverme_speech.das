require ecs
require game.es.sound_net.sound_net_events

[es(tag=sound, on_event=EventEntityDowned, REQUIRE=humanSound)]
def human_coverme_speech_downed(evt : Event; eid : EntityId)
  sendEvent(eid, [[CmdRequestHumanSpeech phrase="coverme"]])
