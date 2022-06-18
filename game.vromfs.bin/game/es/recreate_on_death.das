require ecs
require ecs.common
require strings
require enlisted.events_enlisted

[es(after=hitpoints_es)]
def recreate_on_death(evt : UpdateStageInfoAct)
  var counter = 5
  find_query() <| $ [es] (recreate_dead_entity__maxPerUpdate : int)
    counter = recreate_dead_entity__maxPerUpdate
    return true
  find_query() <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId; isAlive : bool; entity__recreateToOnDeath : string)
    if !isAlive
      sendEventImmediate(eid, [[EventSoldierRecreateOnDie]])
      let sourceFullTemplate = getEntityFutureTemplateName(eid)
      let sourceTemplates <- split_template(sourceFullTemplate)
      var destTemplate = entity__recreateToOnDeath
      if length(sourceTemplates) > 1
        let baseTemplate = sourceTemplates[0]
        let subTemlates = replace(sourceFullTemplate, "{baseTemplate}+", "")
        destTemplate = "{entity__recreateToOnDeath}+{subTemlates}"
      reCreateEntityFrom(eid, destTemplate)
      return --counter == 0
    return false
