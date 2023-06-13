require ecs
require sound_utils.modules.sound_utils_events
require enlisted.events_enlisted
require enlisted.game.es.terraform.terraform_common
require soundHash


[es(tag=sound)]
def human_dig_sound(evt : EventOnDig; eid : EntityId)
  if evt.canTerraformCheckResult == int(CanTerraformCheckResult Successful)
    sendEvent(eid, [[CmdPlaySound hash=sound_hash("terraform")]])
