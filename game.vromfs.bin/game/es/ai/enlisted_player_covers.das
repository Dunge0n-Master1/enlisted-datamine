require ecs
require app
require CollRes
require Covers
require math
require DagorMath
require DagorSystem

// when switching soldier, we can get data desync(in other systems)
// therefore, the array of slots must always be cleaned/filled
// therefore, using a separate flag to indicate that a cover is busy is pointless

def reset_covers(var covers : CoversComponent&;
                 var cover_updater__heldCovers : ecs::IPoint2List&)
  for coverId in cover_updater__heldCovers
    if --covers.coverDescs[coverId.x].slots[coverId.y].numUsed == 0
      --covers.coverDescs[coverId.x].numUsedSlots;

    if covers.coverDescs[coverId.x].slots[coverId.y].numUsed < 0
      logerr("coverDescs numUsed overflow")
    if covers.coverDescs[coverId.x].numUsedSlots < 0
      logerr("coverDescs numUsedSlots overflow")

  clear(cover_updater__heldCovers)


def fill_cover(id : int;
               var covers : CoversComponent&;
               var cover_updater__heldCovers : ecs::IPoint2List&)
  var slotId = 0
  for slot in covers.coverDescs[id].slots
    push(cover_updater__heldCovers, int2(id, slotId++))
    if ++slot.numUsed == 1
      ++covers.coverDescs[id].numUsedSlots;

[es(tag=server, REQUIRE=player, before=(beh_tree_update_es))]
def update_ai_covers(act : UpdateStageInfoAct;
                     possessed : EntityId;
                     covers__coversCheckInterval : float;
                     var covers__nextCoversCheckTime : float&)
  if !possessed || act.curTime < covers__nextCoversCheckTime
    return

  covers__nextCoversCheckTime = act.curTime + covers__coversCheckInterval

  query() <| $ [es] (var covers : CoversComponent&)
    query(possessed) <| $ [es] (transform : float3x4;
                                collres : CollisionResource;
                                var cover_updater__heldCovers : ecs::IPoint2List&)
      var box = collres.vFullBBox

      box.bmin.xyz += transform[3]
      box.bmax.xyz += transform[3]

      reset_covers(covers, cover_updater__heldCovers)

      covers_box_cull(covers, box) <| $(id : int;
                                        tm : mat44f#)
        let ptA = (box.bmin.xyz + box.bmax.xyz) * 0.5
        let ptB = transform[3]

        if isPointInCover(covers, tm, ptA) || isPointInCover(covers, tm, ptB)
          fill_cover(id, covers, cover_updater__heldCovers)