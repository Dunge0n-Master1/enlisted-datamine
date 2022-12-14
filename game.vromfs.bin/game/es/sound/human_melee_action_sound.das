require ecs
require soundEvent
require game.es.sound.sound_events
require sound_utils.modules.sound_physmat_common


[es(tag=sound)]
def human_melee_action_sound(evt : CmdStartActionSfx;
                             human_melee_action_sound__path : string;
                             human_weap__gunEids : EidList;
                             human_weap__currentGunSlot : int)
  if evt.pmid >= 0
    let smid = get_human_melee_action_sound_material_id(evt.pmid)
    if smid >= 0.
      let gunEid = human_weap__currentGunSlot >= 0 ? human_weap__gunEids[human_weap__currentGunSlot] : INVALID_ENTITY_ID
      var path = human_melee_action_sound__path
      query(gunEid) <| $ [es] (meleeActionSoundPath : string)
        path = meleeActionSoundPath
      oneshot("[mat={smid}]{path}", evt.pos)
