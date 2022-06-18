require ecs
require app
require strings
require enlisted.events_enlisted
require RendInst
require RiDestr
require Dacoll
require DagorMath
require DagorMathUtils
require DagorSystem
require DagorConsole


def rirmv_log(start_time : int64; msg : string)
  let elapsedTime = float(get_time_usec(start_time)) * 0.001
  let frameNo = int(get_dagor_frame_no())
  print("rirmv_log: ({format("%.2f", elapsedTime)}ms/{frameNo}) {msg}")


def is_nearly_same_float3(a, b)
  let eps = 0.001
  if abs(a.x - b.x) > eps
    return false
  if abs(a.y - b.y) > eps
    return false
  if abs(a.z - b.z) > eps
    return false
  return true

def is_nearly_same_ri_tm(a, b)
  if !is_nearly_same_float3(a[0], b[0])
    return false
  if !is_nearly_same_float3(a[1], b[1])
    return false
  if !is_nearly_same_float3(a[2], b[2])
    return false
  if !is_nearly_same_float3(a[3], b[3])
    return false
  return true

def remove_rendinst(tm, name) : bool
  var result = false
  let poolsCount = rendinst_getRiGenExtraResCount()
  for pool_id in range(poolsCount)
    let riName = riex_getRIGenExtraName(uint(pool_id))
    if riName != name
      continue
    let over = 5.0
    var bbox : bbox3f
    let off = float3(over, over, over)
    let pt1 = tm[3] - off
    let pt2 = tm[3] + off
    bbox.bmin = float4(pt1, 0.f)
    bbox.bmax = float4(pt2, 0.f)
    getRiGenExtraInstances(pool_id, bbox) <| $(handles : array<riex_handle_t>#)
      for handle in handles
        if !riex_isRiGenExtraValid(handle)
          continue
        if find_ri_extra_eid(handle) != INVALID_ENTITY_ID
          continue
        var riTm : float3x4
        get_rigen_extra_matrix(handle, riTm)
        if is_nearly_same_ri_tm(tm, riTm)
          var out_desc = RendInstDesc()
          destroyRendinst(RendInstDesc(handle), out_desc)
          rendinst_delRIGenExtra(out_desc.riExtraHandle)
          result = true
          return
  return result

def remove_rendinsts(rmv_list : Array)
  let startTime = ref_time_ticks()

  var count = 0
  for rmv in rmv_list
    let obj = get_ecs_object(rmv)
    if obj == null
      continue
    let tm = get_TMatrix(*obj, "tm")
    if tm == null
      continue
    let name = get_string(*obj, "name", "")
    if remove_rendinst(*tm, name)
      ++count

  rirmv_log(startTime, "removed {count}/{length(rmv_list)} instances")


[es(tag=server, on_event=EventLevelLoaded, before=terraforming_apply_server_es)]
def scenery_rendinsts_removes_server_apply_es(evt : Event;
                                              rirmv : Array;
                                              riunb : Array)
  remove_rendinsts(rirmv)
  remove_rendinsts(riunb)

[es(tag=netClient, on_event=EventLevelLoaded, before=terraforming_apply_netclient_es)]
def scenery_rendinsts_removes_netclient_apply_es(evt : Event;
                                                 rirmv : Array;
                                                 riunb : Array)
  remove_rendinsts(rirmv)
  remove_rendinsts(riunb)


// -------------------------------------------------------------------------------------------
// for Editor
// -------------------------------------------------------------------------------------------

[es(tag=gameClient)]
def scenery_rendinsts_remove_rendinst_es(evt : CmdRIToolRemoveRendInst;
                                         var rirmv : Array&)
  if evt.eid != INVALID_ENTITY_ID
    if has(evt.eid, "unbakedRendInstTag")
      destroyEntity(evt.eid)
      return
    if has(evt.eid, "rebakedRendInstTag")
      destroyEntity(evt.eid)
      using() <| $(var obj : Object#)
        obj |> set("tm", evt.tm)
        obj |> set("name", evt.name)
        rirmv |> push(obj)
    return

  if !remove_rendinst(evt.tm, evt.name)
    return

  using() <| $(var obj : Object#)
    obj |> set("tm", evt.tm)
    obj |> set("name", evt.name)
    rirmv |> push(obj)

[es(tag=gameClient)]
def scenery_rendinsts_unbake_rendinst_es(evt : CmdRIToolUnbakeRendInst;
                                         var riunb : Array&)
  var rebaked = false
  if evt.eid != INVALID_ENTITY_ID
    rebaked = has(evt.eid, "rebakedRendInstTag")
    if !rebaked
      return

  if rebaked
    destroyEntity(evt.eid)
  elif !remove_rendinst(evt.tm, evt.name)
    return

  using() <| $(var obj : Object#)
    obj |> set("tm", evt.tm)
    obj |> set("name", evt.name)
    riunb |> push(obj)

  broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="unbaked_rendinst", tm=evt.tm, name=evt.name]])

[es(tag=gameClient)]
def scenery_rendinsts_rebake_rendinst_es(evt : CmdRIToolRebakeRendInst;
                                         var riunb : Array&)
  if evt.eid == INVALID_ENTITY_ID
    return
  if !has(evt.eid, "unbakedRendInstTag")
    return

  let rebakeTm = get_TMatrix(evt.eid, "rebake__tm")
  if rebakeTm == null
    return
  let rebakeName = get_string(evt.eid, "rebake__name", "")
  if rebakeName == ""
    return

  for idx in iter_range(riunb)
    let obj = get_ecs_object(riunb[idx])
    if obj == null
      continue
    let name = get_string(*obj, "name", "")
    if name != rebakeName
      continue
    let tm = get_TMatrix(*obj, "tm")
    if tm == null
      continue
    if !is_nearly_same_ri_tm(*tm, *rebakeTm)
      continue
    broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="rebaked_rendinst", tm=*rebakeTm, name=rebakeName]])
    destroyEntity(evt.eid)
    riunb |> erase(idx)
    break

[es(tag=gameClient)]
def scenery_rendinsts_restore_rendinst_es(evt : CmdRIToolRestoreRendInst;
                                          var rirmv : Array&)
  let cnt = length(rirmv)
  if cnt <= 0
    return

  for i in range(0, cnt)
    let idx = cnt - 1 - i
    let obj = get_ecs_object(rirmv[idx])
    if obj == null
      continue
    let rebakeName = get_string(*obj, "name", "")
    if rebakeName == ""
      continue
    let rebakeTm = get_TMatrix(*obj, "tm")
    if rebakeTm == null
      continue
    let pos = (*rebakeTm)[3]
    let poolsCount = rendinst_getRiGenExtraResCount()
    var radius = 10.0 // safe default
    for pool_id in range(poolsCount)
      let riName = riex_getRIGenExtraName(uint(pool_id))
      if riName == rebakeName
        radius = riex_getBsphRad(uint(pool_id))
        break
    console_command("daEd4.zoom {pos.x} {pos.y+radius*0.618} {pos.z} {radius}")
    broadcastEventImmediate([[CmdRIToolCreateRendInst tpl="rebaked_rendinst", tm=*rebakeTm, name=rebakeName]])
    rirmv |> erase(idx)
    break
