import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")


/*


      THIS SHOULD BE CHANGED!

      We need only watched hero squad query (by some tag)

      Otherwise code is both slower and incorrect!


*/

let defSquadState = freeze({
  heroSquadOrderType = 0
  hasPersonalOrder = false
  isLeaderNeedsAmmo = false
  hasSpaceForMagazine = false
  isCompatibleWeapon = false
  canChangeSquadMember = true
})
let {squadState, squadStateSetValue} = mkFrameIncrementObservable(defSquadState, "squadState")
let {heroSquadOrderType, hasPersonalOrder, isLeaderNeedsAmmo,
  hasSpaceForMagazine, isCompatibleWeapon, canChangeSquadMember
} = watchedTable2TableOfWatched(squadState)

let squadEid = Watched(ecs.INVALID_ENTITY_ID)
let heroSquadNumAliveMembers = Watched(-1)
ecs.register_es("hero_squad_eid_es",
  {
    [["onInit", "onChange"]] = function(_, _eid, comp) {
      let sEid = comp["squad_member__squad"]
      squadEid.update(sEid)
      let alive = squadEid.value != ecs.INVALID_ENTITY_ID
        ? ecs.obsolete_dbg_get_comp_val(sEid, "squad__numAliveMembers", -1)
        : -1
      heroSquadNumAliveMembers(alive)
    },
  },
  { comps_track = [["squad_member__squad", ecs.TYPE_EID],]
    comps_rq = ["human_input"]
  })

ecs.register_es("hero_squad_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp) {
      if (eid != squadEid.value && eid != ecs.INVALID_ENTITY_ID)
        return
      heroSquadNumAliveMembers(comp["squad__numAliveMembers"])
      squadStateSetValue({
        heroSquadOrderType = comp["squad__orderType"]
        hasPersonalOrder = comp["squad__hasPersonalOrder"]
        isLeaderNeedsAmmo = comp["squad__isLeaderNeedsAmmo"]
        hasSpaceForMagazine = comp["order_ammo__hasSpaceForMagazine"]
        isCompatibleWeapon = comp["order_ammo__isCompatibleWeapon"]
        canChangeSquadMember = comp["squad__canChangeMember"]
      })
    }
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
  heroSquadNumAliveMembers
  heroSquadOrderType
  hasPersonalOrder
  isLeaderNeedsAmmo
  hasSpaceForMagazine
  isCompatibleWeapon
  canChangeSquadMember
}