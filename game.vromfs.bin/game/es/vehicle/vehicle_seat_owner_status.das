require ecs

[es(tag=server, no_order)]
def vehicle_seat_update_owner_status(info : UpdateStageInfoAct;
                                     seat__ownerEid : EntityId;
                                     var seat__isPlayer : bool&;
                                     var seat__isOwnerAlive : bool&)
  seat__isOwnerAlive = false
  seat__isPlayer = false
  query(seat__ownerEid) <| $ [es] (isAlive : bool; possessedByPlr : EntityId = INVALID_ENTITY_ID)
    seat__isPlayer = possessedByPlr != INVALID_ENTITY_ID
    seat__isOwnerAlive = isAlive
