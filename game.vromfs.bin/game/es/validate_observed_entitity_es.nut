import "%dngscripts/ecs.nut" as ecs
/*
  currently there can be more than one observed entity - it happens when controlled hero dies but entity still exists
  this is workaround
  however better would be to set watchedByPlr ONLY by specTarget, watchedByPlr should be only calculated from specTarget
*/
from "%enlSqGlob/library_logs.nut" import *
let findObservedQuery = ecs.SqQuery("find_observed_entity", {comps_ro = [["watchedByPlr", ecs.TYPE_EID]]})

let removeObserved = @(not_correct_observed) ecs.recreateEntityWithTemplates({eid = not_correct_observed, removeTemplates = [{template="observed_local", comps= ["watchedByPlr"]}]})

let function validateObservedEntity(valid_target) {
  if (valid_target == INVALID_ENTITY_ID)
    return
  let incorrect_observed_eids = ecs.query_map(findObservedQuery, @(observed_eid, _comp) observed_eid).filter(@(observed_eid) observed_eid != valid_target)

  if (incorrect_observed_eids.len() > 0){
    log("clearing incorrect obervables. target", valid_target, "incorrect observed eids:", incorrect_observed_eids)
    incorrect_observed_eids.each(removeObserved)
  }
}

ecs.register_es("validate_observed_entity_es",
  {
    [["onChange", "onInit"]] = function(_eid, comp){
      if (comp["is_local"])
        validateObservedEntity(comp["specTarget"])
    },
  },
  {
    comps_track = [["specTarget", ecs.TYPE_EID], ["is_local", ecs.TYPE_BOOL]],
    comps_rq = ["player"]
  },
  {tags= "gameClient"}
)

ecs.register_es("validate_observed_entity_by_possessed_es",
  {
    [["onChange", "onInit"]] = function(_eid, comp){
      if (comp["is_local"] && comp.specTarget == INVALID_ENTITY_ID)
        validateObservedEntity(comp["possessed"])
    },
  },
  {
    comps_ro = [["specTarget", ecs.TYPE_EID]]
    comps_track = [["possessed", ecs.TYPE_EID], ["is_local", ecs.TYPE_BOOL]],
    comps_rq = ["player"]
  },
  {tags= "gameClient"}
)

