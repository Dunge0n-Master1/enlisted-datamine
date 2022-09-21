require ecs
/*
  currently there can be more than one observed entity - it happens when controlled hero dies but entity still exists
  this is workaround
  however better would be to set watchedByPlr ONLY by specTarget, watchedByPlr should be only calculated from specTarget
*/

def validate_observed(valid_target : EntityId)
  if !valid_target
    return

  query() <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId)
    if eid != valid_target
      removeSubTemplate(eid, "observed_local")
      print("clearing incorrect obervables: {eid}. valid is {valid_target}")

[es(tag=gameClient, REQUIRE=player, on_appear, track=(specTarget, possessed, is_local))]
def validate_observed_entity_es(evt : Event;
                                possessed : EntityId;
                                specTarget : EntityId;
                                is_local : bool)
  if is_local
    validate_observed(!specTarget ? possessed : specTarget)
