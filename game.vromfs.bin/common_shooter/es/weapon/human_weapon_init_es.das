require ecs
require ecs.safe
require HumanPhys
require common_shooter.events_common_shooter

def init_slot_mods(slot : int;
                   human_weap__weapInfo : Array;
                   var human_weap__gunModsBySlot : Array&)
  let gunMods = (human_weap__weapInfo?[slot] ?as Object)?.gunMods ?as Object
  if gunMods != null
    set(human_weap__gunModsBySlot[slot], *gunMods)

[es(tag=server, on_appear, on_event=CmdReinitWeapons, before=(human_weap_reinit_guns_es, server_init_gun_es, human_weap_created_server_es), REQUIRE=human_weap)]
def human_weapon_init_es(evt : Event;
                         human_weap__weapInfo : Array;
                         var human_weap__gunModsBySlot : Array&)
  let gunsCount = min(int(HUWeaponSlots EWS_NUM), length(human_weap__weapInfo))
  for i in range(gunsCount)
    init_slot_mods(i, human_weap__weapInfo, human_weap__gunModsBySlot)

[es(tag=server, before=human_weap_server_recreate_gun_for_slot)]
def human_weapon_reinit_slot_mods(evt : CmdReinitWeaponInSlot;
                                  human_weap__weapInfo : Array;
                                  var human_weap__gunModsBySlot : Array&)
  init_slot_mods(evt.slot, human_weap__weapInfo, human_weap__gunModsBySlot)
