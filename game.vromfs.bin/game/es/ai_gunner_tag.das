require ecs
require EnlistedWeapon
require vehicle

def manage_ai_gunner_tag(eid : EntityId; condition : bool)
  let hasTag = has(eid, "aiGunner")
  if !hasTag && condition
    addSubTemplate(eid, "ai_gunner")
  elif hasTag && !condition
    removeSubTemplate(eid, "ai_gunner")

[es(tag=server, track=(seat__ownerEid, seat__isPlayer, seat__ownerControls))]
def ai_gunner_track_seat_owner(evt : Event;
                               seat__ownerEid : EntityId;
                               seat__isPlayer : bool;
                               seat__ownerControls : VehicleControlsState)
  let isAiGunner = !!seat__ownerEid && !seat__isPlayer && can_control_turrets(seat__ownerControls)
  manage_ai_gunner_tag(seat__ownerEid, isAiGunner)

[es(tag=server, on_appear, track=isInVehicle, REQUIRE=aiGunner)]
def reset_ai_gunner(evt : Event; eid : EntityId; isInVehicle : bool)
  if !isInVehicle
    removeSubTemplate(eid, "ai_gunner")

