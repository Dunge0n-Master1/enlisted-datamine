require ecs
require game.es.sound_net.sound_net_events


[es(on_event=EventWeapOnReload, tag=server, REQUIRE=human_speech__speeches)]
def human_net_speech_reload(evt : Event; eid : EntityId; human_weap__currentGunEid : EntityId)
  if !has(human_weap__currentGunEid, "disableReloadSpeech")
    sendEvent(eid, [[CmdRequestHumanSpeech phrase="reload"]])
