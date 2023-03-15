require DagorSystem
require DagorMath
require Dacoll
require CollRes
require RendInst
require PhysMat
require EnlistedNet
require enlisted.events_enlisted
require danetlibs.native_dasevents.main.native_events
require game.utils.hero
require ecs.common
require ecs.safe
require ecs
require strings
require player
require math.base

let
  UP = float3(0.0f, 1.0f, 0.0f)
  POSTER_SEARCH_INFLATE = float3(0.25f, 0.0f, 0.0f)
  PLACE_OFFSET = 0.01f
  PLACE_LAYER_OFFSET = 0.005f
  CHECK_POINT_THRES = 0.04f
  AIM_NORM_COS_THRES = 0.6f
  STRAIGHT_PLACE_COS_THRES = 0.25f
  HORZ_PLACE_COS_THRES = 0.5f

enum PlaceStatus : int
  PS_NONE
  PS_OK
  PS_FORBIDDEN
  PS_FORBIDDEN_DESTRUCTIBLE
  PS_FORBIDDEN_HORZ

def traceray_poster(trace_pos : float3;
                    trace_dir : float3;
                    var len : float&;
                    var norm : float3&)
  var matId = PHYSMAT_INVALID
  var riDesc = RendInstDesc()
  let res = traceray_normalized(trace_pos, trace_dir, len, matId, norm, ETF_ALL, riDesc, -1)
  if res && riDesc.isValid
    var retValue = PlaceStatus PS_NONE
    using() <| $(var collInfo : CollisionInfo)
      riDesc |> getRiGenDestrInfo(collInfo)
      if (collInfo.initialHp > 0.0f) || (collInfo.destrImpulse > 0.0f)
        retValue = PlaceStatus PS_FORBIDDEN_DESTRUCTIBLE
        return
      if riDesc.isRiExtra && find_ri_extra_eid(riDesc.riExtraHandle) |> has("isDoor")
        retValue = PlaceStatus PS_FORBIDDEN_DESTRUCTIBLE
        return
    if retValue != PlaceStatus PS_NONE
      return retValue
  return res ? PlaceStatus PS_OK : PlaceStatus PS_FORBIDDEN

def get_template_data(template_name : string;
                      var inst_template_name : string&;
                      var preview_dist : float&;
                      var preview_rot : float3&)
  var tpl = getTemplateByName(template_name)
  if tpl == null
    tpl = buildTemplateByName(template_name)
  if tpl == null
    return
  inst_template_name = getTemplateComponent(*tpl, "instantiateTemplate") ?? ""
  preview_dist = getTemplateComponent(*tpl, "previewDistance") ?? 0.0f
  preview_rot = getTemplateComponent(*tpl, "previewRotation") ?? float3(0.0f, 0.0f, 0.0f)

def check_poster_point(aim_tm : float3x4;
                       plane_point : float3;
                       plane_norm : float3;
                       pt : float3)
  let dir = normalize(pt - aim_tm[3])
  var len = length(pt - aim_tm[3]) + 1.0
  var norm : float3
  if traceray_poster(aim_tm[3], dir, len, norm) != PlaceStatus PS_OK
    return false
  let finalPt = aim_tm[3] + dir * len
  let planeAbsDist = abs(dot(finalPt, plane_norm) + dot(-plane_norm, plane_point))
  return planeAbsDist <= CHECK_POINT_THRES

def calc_poster_transform(aim_tm : float3x4;
                          dist : float;
                          rot : float3;
                          bmin : float3;
                          bmax : float3;
                          var tm : float3x4&;
                          var layer : int&)
  layer = 0
  var status = PlaceStatus PS_NONE
  if length_sq(aim_tm[0]) == 0.0f
    return status
  let traceDir = aim_tm[0]
  let tracePos = aim_tm[3]
  var len = dist
  var norm : float3
  let res = traceray_poster(tracePos, traceDir, len, norm)
  var pos = tracePos + traceDir * len
  if length_sq(norm) == 0.0f
    norm = -aim_tm[0]
  elif dot(-aim_tm[0], norm) >= AIM_NORM_COS_THRES
    status = res
    pos += norm * PLACE_OFFSET
  else
    norm = -aim_tm[0]
  tm[0] = norm
  tm[2] = normalize(cross(tm[0], abs(dot(norm, UP)) < STRAIGHT_PLACE_COS_THRES ? UP : aim_tm[1]))
  tm[1] = normalize(cross(tm[2], tm[0]))
  tm[3] = pos

  var q : quat
  euler_to_quat(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z), q)
  var rotTm : float3x4
  make_tm(q, float3(0.0f, 0.0f, 0.0f), rotTm)
  tm = tm * rotTm

  if status != PlaceStatus PS_NONE
    var maxLayer = -1
    find_query() <| $ [es] (transform : float3x4;
                            wallposter__layer : int;
                            ri_extra__bboxMin : float3;
                            ri_extra__bboxMax : float3)
      if check_bbox3_intersection(BBox3(bmin - POSTER_SEARCH_INFLATE, bmax + POSTER_SEARCH_INFLATE), tm,
        BBox3(ri_extra__bboxMin, ri_extra__bboxMax), transform)
        maxLayer = max(maxLayer, wallposter__layer)
      return false
    if maxLayer >= 0
      layer = maxLayer + 1
      pos += norm * PLACE_LAYER_OFFSET * float(layer)
      tm[3] = pos
  if status == PlaceStatus PS_OK
    if abs(dot(norm, UP)) >= HORZ_PLACE_COS_THRES
      return PlaceStatus PS_FORBIDDEN_HORZ
    let pt1 = tm * bmin
    let pt2 = tm * float3(bmin.x, bmax.y, bmin.z)
    let pt3 = tm * float3(bmax.x, bmin.y, bmax.z)
    let pt4 = tm * float3(bmin.x, bmax.y, bmax.z)
    status = (check_poster_point(aim_tm, pos, norm, pt1) &&
      check_poster_point(aim_tm, pos, norm, pt2) &&
      check_poster_point(aim_tm, pos, norm, pt3) &&
      check_poster_point(aim_tm, pos, norm, pt4)) ? PlaceStatus PS_OK : PlaceStatus PS_FORBIDDEN
  return status

[es(tag=gameClient)]
def wallposter_place_client_es(evt : CmdWallposterPlace;
                               wallPoster__currentId : int;
                               wallPosters__curCount : int)
  var collBb : bbox3f const?
  ecs::query() <| $ [es(REQUIRE=wallposter_preview)] (semi_transparent__resIdx : int)
    collBb = get_rigen_extra_coll_bb(semi_transparent__resIdx)
  if collBb == null
    return
  ecs::find_query() <| $ [es(REQUIRE=hero)] (eid : EntityId; human__aimTm : float3x4)
    send_net_event(eid, [[WallposterRequestPlace wallPosterId=wallPoster__currentId,
      wallPostersCurCount=wallPosters__curCount, tm=human__aimTm, bmin=(*collBb).bmin.xyz, bmax=(*collBb).bmax.xyz]])
    return true

[es(tag=server)]
def wallposter_place_server_es(evt : WallposterRequestPlace;
                               eid : EntityId;
                               isDowned : bool;
                               isAlive : bool;
                               isInVehicle : bool)
  if isDowned || !isAlive || isInVehicle
    return
  let posterId = evt.wallPosterId
  let postersCurCount = evt.wallPostersCurCount
  let playerEid = get_Eid(eid, "possessedByPlr") ?? INVALID_ENTITY_ID
  ecs::query(playerEid) <| $ [es] (wallPosters : Array;
                                   wallPosters__maxCount : int;
                                   var wallPosters__curCount : int&)
    if (postersCurCount != wallPosters__curCount)
      return
    if ((posterId < 0) || (posterId >= length(wallPosters)))
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_index_out_of_range", text="wallposter_place_index_out_of_range"]])
      return
    if (postersCurCount >= wallPosters__maxCount)
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_nomore", text="wallposter_place_nomore"]])
      return
    let tpl = get_string(get_ecs_object(wallPosters[posterId]), "template", "")
    if empty(tpl)
      return
    var instTemplateName : string
    var previewDist : float
    var previewRot : float3
    get_template_data(tpl, instTemplateName, previewDist, previewRot)
    if empty(instTemplateName)
      return
    var tm : float3x4
    var layer : int = 0
    let status = calc_poster_transform(evt.tm, previewDist, previewRot, evt.bmin, evt.bmax, tm, layer)
    if status == PlaceStatus PS_NONE
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_choose_surface", text="wallposter_place_choose_surface"]])
      return
    elif status == PlaceStatus PS_FORBIDDEN
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_not_allowed", text="wallposter_place_not_allowed"]])
      return
    elif status == PlaceStatus PS_FORBIDDEN_DESTRUCTIBLE
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_not_allowed_destructible", text="wallposter_place_not_allowed_destructible"]])
      return
    elif status == PlaceStatus PS_FORBIDDEN_HORZ
      sendEvent(eid, [[CmdHeroLogEvent event="wallposter_place_not_allowed_horz", text="wallposter_place_not_allowed_horz"]])
      return
    verify(status == PlaceStatus PS_OK)
    createEntity(instTemplateName) <| $(var init : ComponentsInitializer)
      set(init, "transform", tm)
      set(init, "wallposter__layer", layer)
    ++wallPosters__curCount

[es(tag=gameClient, track=wallPosters__curCount, REQUIRE=wallPosters__curCount)]
def wallposter_count_change_es(evt : Event; eid : EntityId; is_local : bool)
  if (!is_local)
    return
  sendEventImmediate(eid, [[CmdWallposterPreview enable=false, wallPosterId=0]])

[es(tag=gameClient, track=isAlive, track=isDowned, track=isInVehicle, REQUIRE=hero)]
def wallposter_hero_status_change_es(evt : Event;
                                     isDowned : bool;
                                     isAlive : bool;
                                     isInVehicle : bool)
  if isDowned || !isAlive || isInVehicle
    sendEventImmediate(get_local_player_eid(), [[CmdWallposterPreview enable=false, wallPosterId=0]])

[es(tag=gameClient, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=hero)]
def wallposter_hero_changed_es(evt : Event)
  sendEventImmediate(get_local_player_eid(), [[CmdWallposterPreview enable=false, wallPosterId=0]])

[es(tag=gameClient, on_appear, REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))]
def wallposter_builder_enabled_es(evt : Event)
  sendEventImmediate(get_local_player_eid(), [[CmdWallposterPreview enable=false, wallPosterId=0]])

[es(tag=gameClient)]
def wallposter_preview_toggle_es(evt : CmdWallposterPreview;
                                 var wallPoster__currentId : int&;
                                 var wallPoster__preview : bool&)
  if evt.enable
    var haveBuilderPreview = false
    ecs::query() <| $ [es(REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))] ()
      haveBuilderPreview = true
    if haveBuilderPreview
      let hero = get_controlled_hero()
      sendEvent(hero, [[CmdHeroLogEvent event="wallposter_preview_builder_active", text="wallposter_preview_builder_active"]])
      return
  wallPoster__preview = evt.enable
  wallPoster__currentId = evt.wallPosterId

[es(tag=gameClient, track=wallPoster__currentId, track=wallPoster__preview)]
def wallposter_preview_change_es(evt : Event;
                                 is_local : bool;
                                 wallPoster__currentId : int;
                                 wallPoster__preview : bool;
                                 wallPosters : Array)
  if (!is_local)
    return
  ecs::query() <| $ [es(REQUIRE=wallposter_preview)] (eid : ecs::EntityId)
    destroyEntity(eid)
  if (wallPoster__preview)
    if ((wallPoster__currentId < 0) || (wallPoster__currentId >= length(wallPosters)))
      logwarn("wallposter_preview_change_es: {wallPoster__currentId} out of range [0, {length(wallPosters)})")
      return ;
    let tpl = get_string(get_ecs_object(wallPosters[wallPoster__currentId]), "template", "")
    createEntity(tpl)

[es(tag=gameClient, no_order, REQUIRE=wallposter_preview)]
def wallposter_preview_update_es(info : UpdateStageInfoAct;
                                 previewDistance : float;
                                 previewRotation : float3;
                                 defColor : float3;
                                 okColor : float3;
                                 forbiddenColor : float3;
                                 var transform : float3x4&;
                                 semi_transparent__resIdx : int;
                                 var semi_transparent__placingColor : float3&;
                                 var semi_transparent__visible : bool&)
  let collBb = get_rigen_extra_coll_bb(semi_transparent__resIdx)
  if collBb == null
    return
  ecs::find_query() <| $ [es(REQUIRE=hero)] (human__aimTm : float3x4)
    semi_transparent__visible = true
    var layer : int
    let status = calc_poster_transform(human__aimTm, previewDistance, previewRotation,
      (*collBb).bmin.xyz, (*collBb).bmax.xyz, transform, layer)
    if status == PlaceStatus PS_OK
      semi_transparent__placingColor = okColor
    elif (status != PlaceStatus PS_NONE)
      semi_transparent__placingColor = forbiddenColor
    else
      semi_transparent__placingColor = defColor
    return true
