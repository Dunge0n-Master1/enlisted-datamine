require ecs
require HumanPhys
require soundEvent
require soundHash
require DaWeaponProps
require shellSoundProps
require strings
require common_sounds.modules.common_sounds_events
require sound_utils.modules.sound_player_common


[es(tag=sound)]
def human_shell_irq_sound(evt : CmdSoundSpecificIrq;
                          human_weap__gunEids : EidList;
                          is_watched_sound : bool;
                          transform : float3x4)
  if evt.group == sound_hash("grenadeActivate")
    query(human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]) <| $ [es] (gun__curShellId : ShellPropIds)
      let shellSoundProps = shell_sound_try_get_props(int(gun__curShellId.shellId))
      if shellSoundProps != null
        let path : string = (*shellSoundProps).activatePath
        if !empty(path)
          if should_apply_watched_prefix(path)
            oneshot(is_watched_sound ? "player{path}" : "enemy{path}", transform[3])
          else
            oneshot(path, transform[3])
