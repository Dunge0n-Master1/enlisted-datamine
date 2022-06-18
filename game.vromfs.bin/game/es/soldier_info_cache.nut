import "%dngscripts/ecs.nut" as ecs
let { logerr } = require("dagor.debug")
let { EventLevelLoaded } = require("gameevents")

let getSoldierCacheQuery = ecs.SqQuery("getSoldierCacheQuery", { comps_rw = [["soldierInfoCache", ecs.TYPE_OBJECT]] })

let function save_to_cache(soldier_eid, player, guid) {
  getSoldierCacheQuery(function(_, comp) {
    let key = soldier_eid.tostring()
    if (key in comp.soldierInfoCache)
      logerr("soldierInfoCache: key collision detected. Eid was reused for another soldier?")
    comp.soldierInfoCache[key] <- { player, guid }
  })
}

let get_soldier_info_from_cache = @(soldier_eid)
  getSoldierCacheQuery(@(_, comp) comp.soldierInfoCache?[soldier_eid.tostring()])

ecs.register_es("soldier_info_cache_on_soldier_spawn", {
    [ecs.EventEntityCreated] = function(_, eid, comp) {
      save_to_cache(eid, comp["squad_member__playerEid"], comp.guid)
    }
  },
  {comps_ro = [["guid", ecs.TYPE_STRING], ["squad_member__playerEid", ecs.TYPE_EID]]},
  {tags = "server"}
)

ecs.register_es("soldier_info_cache_init", {
  [EventLevelLoaded] = @(...) ecs.g_entity_mgr.createEntity("soldier_info_cache", {})
}, {})

return get_soldier_info_from_cache