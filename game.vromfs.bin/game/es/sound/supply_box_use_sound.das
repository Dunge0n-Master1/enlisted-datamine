require ecs
require soundEvent
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=localPlayer)]
def paratroopers_supply_box_use_sound(evt : RequestApplySupplyScheme)
  let soundPath = get_string(evt.boxEid, "supply_box__useSound", "")
  if !empty(soundPath)
    oneshot(soundPath)
