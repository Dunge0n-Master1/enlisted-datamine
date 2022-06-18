require ecs
require soundEvent
require game.es.sound.sound_events

[es(tag=sound)]
def action_sfx_sound(evt : CmdStartActionSfx;
                     human_action_sfx_sound__defaultPath : string;
                     human_weap__gunEids : EidList;
                     human_weap__currentGunSlot : int)
  if evt.smid < 0
    return
  let gunEid = human_weap__currentGunSlot >= 0 ? human_weap__gunEids[human_weap__currentGunSlot] : INVALID_ENTITY_ID
  var path = human_action_sfx_sound__defaultPath
  query(gunEid) <| $ [es] (actionSfxSound : string)
    path = actionSfxSound
  oneshot("[mat={evt.smid}]{path}", evt.pos)
