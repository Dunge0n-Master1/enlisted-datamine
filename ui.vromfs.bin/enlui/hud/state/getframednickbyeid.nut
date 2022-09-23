import "%dngscripts/ecs.nut" as ecs
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")

let getPlayerNickAndFrameQuery = ecs.SqQuery("getPlayerNickAndFrame",
  { comps_ro = [
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING],
    ]
  })

let getFramedNickByEid = @(playerEid) getPlayerNickAndFrameQuery.perform(playerEid,
  @(_eid, comp) frameNick(remap_others(comp.name), comp["decorators__nickFrame"]))

return getFramedNickByEid