require ecs
require game.es.sound_net.sound_net_events


[es(tag=server, track=human_melee_charge__isActive)]
def human_melee_charge_net_speech(evt : Event; eid : EntityId;
                                  human_melee_charge__isActive : bool)
  if human_melee_charge__isActive
    sendEvent(eid, [[CmdRequestHumanSpeech phrase="meleeCharge"]])
