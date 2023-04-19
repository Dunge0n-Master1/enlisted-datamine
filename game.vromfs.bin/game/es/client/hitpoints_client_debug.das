options no_aot
require ecs
require ecs.ecs_template
require math.base
require strings
require RendInst
require DagorConsole
require DagorDebug3D


[ecs_template]
struct hitpoints_debug_draw
  hitpoints__debugDrawDist : float = 0.0
  hitpoints__debugDrawDistSq : float = 0.0


[console_cmd(name="hitpoints.debug_hp")]
def hitpoints_debug_draw_cmd(dist = 50.0)
  let tmpl = "hitpoints_debug_draw"
  let distSq = square(dist)

  let exists = find_query() <| $ [es] (eid : EntityId;
                                       var hitpoints__debugDrawDist : float&;
                                       var hitpoints__debugDrawDistSq : float&)
    if hitpoints__debugDrawDist == dist
      destroyEntity(eid)
    else
      hitpoints__debugDrawDist = dist
      hitpoints__debugDrawDistSq = distSq
    return true

  if !exists
    createEntity(tmpl) <| $(init)
      init |> set("hitpoints__debugDrawDist", dist)
      init |> set("hitpoints__debugDrawDistSq", distSq)


[es(tag=(render, dev), no_order)]
def debug_draw_hitpoints_hp_es(evt : UpdateStageInfoRenderDebug;
                               hitpoints__debugDrawDistSq : float)

  find_query() <| $ [es] (camera__active : bool;
                          transform aka camera_transform : float3x4)
    if !camera__active
      return false
    query() <| $ [es] (transform aka hitpoints_transform : float3x4;
                       hitpoints__hp : float;
                       hitpoints__maxHp : float)
      let distSq = distance_sq(camera_transform[3], hitpoints_transform[3])
      if distSq > hitpoints__debugDrawDistSq
        return

      let markPos = hitpoints_transform[3] + float3(0.0, 1.0, 0.0)
      add_debug_text_mark(markPos, "hp:{format("%.2f", hitpoints__hp)}/{format("%.2f", hitpoints__maxHp)}", -1, 0.0, E3DCOLOR(0xFFFFFFFF))
    return true


[ecs_template]
struct ri_hitpoints_debug_draw
  ri_hitpoints__debugDrawDist : float = 0.0


[console_cmd(name="rendinst.debug_hp")]
def ri_hitpoints_debug_draw_cmd(dist = 5.0)
  let tmpl = "ri_hitpoints_debug_draw"

  let exists = find_query() <| $ [es] (eid : EntityId;
                                       var ri_hitpoints__debugDrawDist : float&)
    if ri_hitpoints__debugDrawDist == dist
      destroyEntity(eid)
    else
      ri_hitpoints__debugDrawDist = dist
    return true

  if !exists
    createEntity(tmpl) <| $(init)
      init |> set("ri_hitpoints__debugDrawDist", dist)


[es(tag=(render, dev), no_order)]
def debug_draw_ri_hitpoints_hp_es(evt : UpdateStageInfoRenderDebug;
                                  ri_hitpoints__debugDrawDist : float)

  find_query() <| $ [es] (camera__active : bool;
                          transform aka camera_transform : float3x4)
    if !camera__active
      return false
    let box = BBox3(transform[3] - float3(ri_hitpoints__debugDrawDist), transform[3] + float3(ri_hitpoints__debugDrawDist))
    rendinst_foreachRIGenInBox(box, true) <| $ [unused_argument(is_tm)] (desc : RendInstDesc; tm : float3x4; is_tm : bool)
      if !riex_isRiGenExtraValid(desc.riExtraHandle)
        return

      let initialHp = riex_getInitialHP(desc.riExtraHandle)
      if initialHp < 0.0
        return

      let hp = riex_get_hp(desc.riExtraHandle)
      add_debug_text_mark(tm[3], "hp:{format("%.2f", hp)}/{format("%.2f", initialHp)}", -1, 0.0, E3DCOLOR(0xFFFFFFFF))
    return true