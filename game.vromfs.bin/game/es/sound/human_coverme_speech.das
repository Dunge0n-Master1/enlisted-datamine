require ecs
require human_sounds_net.modules.human_sounds_net_events

[es(tag=sound, on_event=EventEntityDowned, REQUIRE=humanSound)]
def human_coverme_speech_downed(evt : Event; eid : EntityId)
  sendEvent(eid, [[CmdRequestHumanSpeech phrase="coverme"]])
