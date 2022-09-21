import "%dngscripts/ecs.nut" as ecs
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let getPlayerNickAndFrameQuery = ecs.SqQuery("getPlayerNickAndFrame",
  { comps_ro = [
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING],
    ]
  })

let getFramedNickByEid = @(playerEid) getPlayerNickAndFrameQuery.perform(playerEid,
  @(_eid, comp) frameNick(
    comp.name == userInfo.value?.name ? userInfo.value.nameorig : remap_nick(comp.name),
    comp["decorators__nickFrame"]
  ))

return getFramedNickByEid