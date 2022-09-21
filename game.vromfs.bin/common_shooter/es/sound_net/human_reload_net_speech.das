require ecs
require game.es.sound_net.sound_net_events


[es(on_event=EventWeapOnReload, tag=server, REQUIRE=human_speech__speeches)]
def human_net_speech_reload(evt : Event; eid : EntityId)
  sendEvent(eid, [[CmdRequestHumanSpeech phrase="reload", importance=1.]])
