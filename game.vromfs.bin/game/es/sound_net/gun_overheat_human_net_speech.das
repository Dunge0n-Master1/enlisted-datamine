require ecs
require app
require game.es.sound_net.sound_net_events

[es(track=gun__isOverheat, tag=server, REQUIRE=gunOverheatSpeechEnable)]
def gun_overheat_human_net_speech_es(evt : Event;
                                     gun__isOverheat : bool;
                                     gun__owner : EntityId)
  if gun__isOverheat
    sendEvent(gun__owner, [[CmdRequestHumanSpeech phrase="gunOverheat"]])
