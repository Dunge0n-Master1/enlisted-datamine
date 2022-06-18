import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *


let squadEid = mkWatched(persist, "squadEid", INVALID_ENTITY_ID)
let numAliveMembers = mkWatched(persist, "numAliveMembers", -1)
let orderType = mkWatched(persist, "orderType", 0)
let hasPersonalOrder = mkWatched(persist, "hasPersonalOrder", false)
let isLeaderNeedsAmmo = mkWatched(persist, "isLeaderNeedsAmmo", false)
let hasSpaceForMagazine = mkWatched(persist, "hasSpaceForMagazine", false)
let isCompatibleWeapon = mkWatched(persist, "isCompatibleWeapon", false)
let canChangeSquadMember = mkWatched(persist, "canChangeSquadMember", true)

let function updateSquadEid(_eid, comp) {
  squadEid(comp["squad_member__squad"])
  local alive = -1
  if (squadEid.value != INVALID_ENTITY_ID)
    alive = ecs.obsolete_dbg_get_comp_val(squadEid.value, "squad__numAliveMembers", -1)
  numAliveMembers(alive)
}

let function updateSquadParams(eid, comp) {
  if (eid != squadEid.value && eid != INVALID_ENTITY_ID)
    return
  numAliveMembers(comp["squad__numAliveMembers"])
  orderType(comp["squad__orderType"])
  hasPersonalOrder.update(comp["squad__hasPersonalOrder"])
  isLeaderNeedsAmmo.update(comp["squad__isLeaderNeedsAmmo"])
  hasSpaceForMagazine.update(comp["order_ammo__hasSpaceForMagazine"])
  isCompatibleWeapon.update(comp["order_ammo__isCompatibleWeapon"])
  canChangeSquadMember(comp["squad__canChangeMember"])
}

ecs.register_es("hero_squad_eid_es",
  {
    [["onInit", "onChange"]] = updateSquadEid,
  },
  { comps_track = [["squad_member__squad", ecs.TYPE_EID],]
    comps_rq = ["human_input"]
  })

ecs.register_es("hero_squad_es",
  {
    [["onInit", "onChange"]] = updateSquadParams,
  },
  {
    comps_track = [
      ["order_ammo__hasSpaceForMagazine", ecs.TYPE_BOOL],
      ["order_ammo__isCompatibleWeapon", ecs.TYPE_BOOL],
      ["squad__numAliveMembers", ecs.TYPE_INT],
      ["squad__orderType", ecs.TYPE_INT],
      ["squad__hasPersonalOrder", ecs.TYPE_BOOL],
      ["squad__isLeaderNeedsAmmo", ecs.TYPE_BOOL],
      ["squad__canChangeMember", ecs.TYPE_BOOL],
    ]
  })

return {
  squadEid
  heroSquadNumAliveMembers = numAliveMembers
  heroSquadOrderType = orderType
  hasPersonalOrder
  isLeaderNeedsAmmo
  hasSpaceForMagazine
  isCompatibleWeapon
  canChangeSquadMember
}