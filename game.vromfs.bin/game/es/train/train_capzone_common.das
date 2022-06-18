module train_capzone_common shared

require ecs
require game.utils.team

def get_next_train_checkpoint()
  var nextZoneEid = INVALID_ENTITY_ID
  var minUiOrder = -1
  query() <| $ [es(REQUIRE=trainTriggerable)] (eid : EntityId;
                                               capzone__alwaysHide : bool;
                                               capzone__alwaysShow : bool;
                                               ui_order : int;
                                               capzone__owningTeam : int;
                                               capzone__capTeam : int)
    let isCaptured = capzone__owningTeam != TEAM_UNASSIGNED && capzone__owningTeam == capzone__capTeam
    if capzone__alwaysShow && !capzone__alwaysHide && !isCaptured && (minUiOrder < 0 || ui_order < minUiOrder)
      nextZoneEid = eid
      minUiOrder = ui_order
  return nextZoneEid