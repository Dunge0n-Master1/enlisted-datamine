require ecs
require RendInst
require DagorMath
require DagorTime
require WorldRenderer
require ecs.ecs_template


def invalidate_bsphere_shadow(bsph : float4)
  let pt1 = float3(bsph.x - bsph.w, bsph.y - bsph.w, bsph.z - bsph.w)
  let pt2 = float3(bsph.x + bsph.w, bsph.y + bsph.w, bsph.z + bsph.w)
  let bbox = BBox3(pt1, pt2)
  worldRenderer_shadowsInvalidate(bbox)

def invalidate_riextra_shadow(ri_extra : RiExtraComponent; var prevBsph : float4&)
  let bsph = getRIGenExtraBSphere(ri_extra.handle)
  if prevBsph.w > 0.0
    invalidate_bsphere_shadow(prevBsph)
  applyTiledScenesUpdateForRIGenExtra(2000, 1000)
  rendinst_moveToOriginalScene(ri_extra.handle)
  invalidate_bsphere_shadow(bsph)
  prevBsph = bsph


[ecs_template]
struct scenery_rendinsts_shadow_invalidate
  nonCreatableObj : bool = true
  scenery_rendinsts_shadow_invalidate__eid  : EntityId
  scenery_rendinsts_shadow_invalidate__time : float

def invalidate_riextra_shadow_delayed(eid : EntityId)
  let delay = 0.01
  createEntity("scenery_rendinsts_shadow_invalidate") <| $(var init : ComponentsInitializer)
    set(init, "scenery_rendinsts_shadow_invalidate__eid", eid)
    set(init, "scenery_rendinsts_shadow_invalidate__time", float(get_time_msec()) * 0.001 + delay)

[es(tag=render, no_order)]
def scenery_rendinsts_init_shadows_rebaked_finalize_es(info : UpdateStageInfoAct;
                                                       eid : EntityId;
                                                       scenery_rendinsts_shadow_invalidate__eid : EntityId;
                                                       scenery_rendinsts_shadow_invalidate__time : float)
  let time = float(get_time_msec()) * 0.001
  if time < scenery_rendinsts_shadow_invalidate__time
    return
  query(scenery_rendinsts_shadow_invalidate__eid) <| $ [es] (ri_extra : RiExtraComponent;
                                                             var ri_shadow__prevBSphere : float4&)
    invalidate_riextra_shadow(ri_extra, ri_shadow__prevBSphere)
  destroyEntity(eid)


[es(tag=render, on_appear, on_event=EventEditorEntityMoved, REQUIRE=(gameRendInstTag))]
def scenery_rendinsts_init_shadows_gameri_es(evt : Event;
                                             ri_extra : RiExtraComponent;
                                             var ri_shadow__prevBSphere : float4&)
  invalidate_riextra_shadow(ri_extra, ri_shadow__prevBSphere)

[es(tag=render, on_appear, on_event=EventEditorEntityMoved, REQUIRE=(unbakedRendInstTag))]
def scenery_rendinsts_init_shadows_unbaked_es(evt : Event;
                                              ri_extra : RiExtraComponent;
                                              var ri_shadow__prevBSphere : float4&)
  invalidate_riextra_shadow(ri_extra, ri_shadow__prevBSphere)

[es(tag=render, on_appear, REQUIRE=(rebakedRendInstTag))]
def scenery_rendinsts_init_shadows_rebaked_es(evt : Event; eid : EntityId)
  invalidate_riextra_shadow_delayed(eid)


// NOTE: It seems now this code not required because when RI removed shadows already invalidated, commented for now (for future)
//
//def invalidate_removed_riextra_shadow(tm, name)
//  let poolsCount = rendinst_getRiGenExtraResCount()
//  for pool_id in range(poolsCount)
//    let riName = riex_getRIGenExtraName(uint(pool_id))
//    if riName != name
//      continue
//    let bsph = getRIGenExtraBSphereByTM(uint(pool_id), tm)
//    invalidate_bsphere_shadow(bsph)
//
//def invalidate_removed_riextras_shadows(rmv_list : Array)
//  for rmv in rmv_list
//    let obj = get_ecs_object(rmv)
//    if obj == null
//      continue
//    let tm = get_TMatrix(*obj, "tm")
//    if tm == null
//      continue
//    let name = get_string(*obj, "name", "")
//    invalidate_removed_riextra_shadow(*tm, name)
//
//[es(tag=render, on_event=EventLevelLoaded, after=(scenery_rendinsts_removes_server_apply_es, scenery_rendinsts_removes_netclient_apply_es))]
//def scenery_rendinsts_init_shadows_removed_es(evt : Event; rirmv : Array; riunb : Array)
//  invalidate_removed_riextras_shadows(rirmv)
//  invalidate_removed_riextras_shadows(riunb)
