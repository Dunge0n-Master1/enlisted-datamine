require ecs
require ecs.common
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common
require game.es.events
require common_shooter.events_common_shooter

[es(tag=sound)]
def gun_sound_tags_track(evt : EventOnInstallWeapMod;
                         human_weap__gunEids : EidList;
                         human_weap__gunMods : Array)
  if uint(evt.gunSlotId) < uint(length(human_weap__gunEids))
    query(human_weap__gunEids[evt.gunSlotId]) <| $ [es] (var sound_tags : Object&)
      clear(sound_tags)
      for i in iter_range(human_weap__gunMods)
        let gunModEids = get_ecs_EidList(human_weap__gunMods[i])
        for gunMod in *gunModEids
          query(gunMod) <| $ [es] (gunObject : StringList)
            for tag in gunObject
              raise_sound_tag(string(tag), sound_tags)
