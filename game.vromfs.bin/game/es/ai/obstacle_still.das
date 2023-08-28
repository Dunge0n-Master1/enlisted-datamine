require ecs
require game.es.events
require pathfinder
require strings
require DagorMath
require DagorSystem
require CollRes
require RendInst
require app
require enlisted.game.es.fortifications_build_common

let
  FORWARD = float3(1.0f, 0.0, 0.0f)

def add_obstacle_template(eid : EntityId; transform : float3x4; cur_time : float; obstacle_template : string)
  addSubTemplate(eid, obstacle_template) <| $(var init : ComponentsInitializer)
    set(init, "obstacle__lastStillTransform", transform)
    set(init, "obstacle__lastStillTime", cur_time)

def still_player_obstacles_from_grid(cur_time : float; obstacle_template : string)
  ecs::query() <| $ [es(REQUIRE_NOT=(obstacle__still, obstacle__handle, deadEntity), REQUIRE=(human, collres, grid_obj))] (eid : EntityId; transform : float3x4; beh_tree__enabled : bool)
    if !beh_tree__enabled
      add_obstacle_template(eid, transform, cur_time, obstacle_template)

  ecs::query() <| $ [es(REQUIRE=(human, obstacle__still))] (eid : EntityId; isAlive : bool; beh_tree__enabled : bool = false)
    if beh_tree__enabled || !isAlive
      removeSubTemplate(eid, obstacle_template)

def still_obstacles_from_grid(cur_time : float; obstacle_template : string)
  ecs::query() <| $ [es(REQUIRE_NOT=(obstacle__still, human, obstacle__handle, moveable_obstacle),
                        REQUIRE=(collres, grid_obj))] (eid : EntityId;
                                                       transform : float3x4;
                                                       grid_obj__hidden : int = 0;
                                                       grid_obj__gridType : string = "")
    if grid_obj__hidden == 0 && (empty(grid_obj__gridType) || (grid_obj__gridType == "vehicles"))
      add_obstacle_template(eid, transform, cur_time, obstacle_template)

  ecs::query() <| $ [es(REQUIRE=obstacle__still)] (eid : EntityId; grid_obj__hidden : int)
    if grid_obj__hidden != 0
      removeSubTemplate(eid, obstacle_template)

def still_obstacles_from_riextra(cur_time : float; obstacle_template : string)
  ecs::query() <| $ [es(REQUIRE_NOT=(obstacle__still, obstacle__handle, ri_extra__handle, moveable_obstacle, rallypoint, gameRendInstTag, unbakedRendInstTag))] (eid : EntityId; transform : float3x4; ri_extra : RiExtraComponent)
    let riType = handle_to_ri_type(ri_extra.handle)
    if get_ri_gen_extra_collres(int(riType)) != null
      add_obstacle_template(eid, transform, cur_time, obstacle_template)

def still_obstacles_update(cur_time : float)
  ecs::query() <| $ [es(REQUIRE=obstacle__still,
                        REQUIRE_NOT=(gameRendInstTag, unbakedRendInstTag))] (eid : EntityId;
                                                                             obstacle__checkDelta : float;
                                                                             obstacle__stillPosThreshold : float;
                                                                             obstacle__stillAngCosThreshold : float;
                                                                             obstacle__stillTimeout : float;
                                                                             obstacle__initialStillTimeout : float;
                                                                             obstacle__padding : float = 0.0f;
                                                                             obstacle__paddingSide : float = 0.0f;
                                                                             var obstacle__stillCount : int&;
                                                                             var obstacle__handle : int&;
                                                                             var obstacle__lastCheckTime : float&;
                                                                             var obstacle__lastStillTransform : float3x4&;
                                                                             var obstacle__lastStillTime : float&;
                                                                             transform : float3x4;
                                                                             collres : CollisionResource const?;
                                                                             ri_extra : RiExtraComponent const?;
                                                                             ri_preview__name : das_string const?;
                                                                             previewCollres : CollisionResource const?)
    if (cur_time < obstacle__lastCheckTime + obstacle__checkDelta)
      return
    obstacle__lastCheckTime = cur_time
    if ((length_sq(transform[3] - obstacle__lastStillTransform[3]) > obstacle__stillPosThreshold * obstacle__stillPosThreshold) ||
      (dot(rotate(transform, FORWARD), rotate(obstacle__lastStillTransform, FORWARD)) < obstacle__stillAngCosThreshold))
      obstacle__lastStillTime = cur_time
      obstacle__lastStillTransform = transform
      tilecache_obstacle_remove(obstacle__handle)
      obstacle__handle = 0
      return
    let timeout = (obstacle__stillCount > 0) ? obstacle__stillTimeout : obstacle__initialStillTimeout
    if (cur_time < obstacle__lastStillTime + timeout)
      return
    obstacle__lastStillTime = cur_time
    obstacle__lastStillTransform = transform
    if obstacle__handle == 0
      ++obstacle__stillCount

      var cr : CollisionResource const? = null
      if collres != null
        cr = collres
      elif ri_extra != null
        let riType = handle_to_ri_type((*ri_extra).handle)
        cr = get_ri_gen_extra_collres(int(riType))
      elif previewCollres != null || ri_preview__name != null
        cr = get_building_collres(previewCollres, ri_preview__name)

      if cr != null
        var box = BBox3((*cr).vFullBBox)
        box.boxMin -= float3(0.0f, obstacle__padding, 0.0f)
        bbox3_inflateXZ(box, obstacle__paddingSide)
        obstacle__handle = tilecache_obstacle_add(transform, box)
      else
        logerr("No collision resource in still_obstacles_update: {eid} {getEntityTemplateName(eid)}")


[es(tag=server, on_appear, REQUIRE=builder_server_preview)]
def network_fortification_preview_obstacle(evt : Event; eid : EntityId; transform : float3x4)
  query() <| $ [es] (still_obstacles__obstacleTemplate : string)
    add_obstacle_template(eid, transform, get_sync_time(), still_obstacles__obstacleTemplate)


[es(tag=server, no_order)]
def still_obstacles_check_es(info : UpdateStageInfoAct;
                             var still_obstacles__lastCheckTime : float&;
                             still_obstacles__checkDelta : float;
                             still_obstacles__obstacleTemplate : string)
  if !tilecache_is_loaded()
    return
  if (info.curTime < still_obstacles__lastCheckTime + still_obstacles__checkDelta)
    return
  still_obstacles__lastCheckTime = info.curTime
  still_obstacles_from_grid(info.curTime, still_obstacles__obstacleTemplate)
  still_obstacles_from_riextra(info.curTime, still_obstacles__obstacleTemplate)
  still_player_obstacles_from_grid(info.curTime, still_obstacles__obstacleTemplate)
  still_obstacles_update(info.curTime)
