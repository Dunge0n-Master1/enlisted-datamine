options no_aot
require ecs
require game.es.events
require math.base
require math.color
require RendInst
require DagorMath
require DagorConsole
require DagorDebug3D
require CollRes
require Grid
require ecs.ecs_template


[ecs_template]
struct double_doors_debug
  draw_double_doors : bool

[ecs_template]
struct unpaired_doors_debug
  draw_unpaired_doors : bool

[console_cmd(name="double_doors_debug")]
def debug_double_doors(draw_double_doors : bool = true)
  ecs::query() <| $ [es] (eid : EntityId; camera__active : bool)
    if camera__active
      addSubTemplate(eid, "double_doors_debug") <| $(var init)
        set(init, "draw_double_doors", draw_double_doors)


[es(tag=render, tag=dev, no_order)]
def debug_double_doors_es(evt : UpdateStageInfoRenderDebug; camera__active, draw_double_doors : bool; transform : float3x4)
  if camera__active && draw_double_doors
    begin_draw_cached_debug_lines(true, true, false)

    let camTm = transform
    ecs::query() <| $ [es] (eid, pair_door__eid : EntityId; ri_extra : RiExtraComponent; transform : float3x4)
      if !pair_door__eid || length_sq(camTm[3] - transform[3]) > square(100.0)
        return

      let riType = handle_to_ri_type(ri_extra.handle)
      let collres = get_ri_gen_extra_collres(int(riType))
      if collres == null
        return

      var box = collres.vFullBBox
      let scale = 4.0
      if box.bmin.x < box.bmin.z
        box.bmin.x *= scale
      else
        box.bmin.z *= scale
      if box.bmax.x < box.bmax.z
        box.bmax.x *= scale
      else
        box.bmax.z *= scale

      var seed = int(uint(eid) < uint(pair_door__eid) ? uint(eid) : uint(pair_door__eid))
      let color = rnd_color(seed)

      set_cached_debug_lines_wtm(transform)
      draw_cached_debug_box(BBox3(box), color)

    end_draw_cached_debug_lines()


[console_cmd(name="unpaired_doors_debug")]
def debug_unpaired_doors(draw_unpaired_doors : bool = true)
  ecs::query() <| $ [es] (eid : EntityId; camera__active : bool)
    if camera__active
      addSubTemplate(eid, "unpaired_doors_debug") <| $(var init)
        set(init, "draw_unpaired_doors", draw_unpaired_doors)


[es(tag=render, tag=dev, no_order)]
def unpaired_doors_es(evt : UpdateStageInfoRenderDebug; camera__active, draw_unpaired_doors : bool; transform : float3x4)
  if camera__active && draw_unpaired_doors
    begin_draw_cached_debug_lines(true, true, false)

    let camTm = transform
    ecs::query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId;
                                            ri_extra : RiExtraComponent;
                                            transform : float3x4;
                                            pair_door__eid : EntityId;
                                            pair_door__searchDist : float = 3.0;
                                            pair_door__checkMargin : float = 0.05)
      if pair_door__eid != INVALID_ENTITY_ID || length_sq(camTm[3] - transform[3]) > square(100.0)
        return

      let bounding = BSphere3(transform[3], pair_door__searchDist)
      let found = find_entity_in_grid(ecs_hash("doors"), bounding, GridEntCheck POS) <| $(potentialPairEid : EntityId)
        if potentialPairEid == eid
          return false
        let pairEid = get_Eid(potentialPairEid, "pair_door__eid") ?? INVALID_ENTITY_ID
        return !pairEid

      if found != INVALID_ENTITY_ID
        return

      let riType = handle_to_ri_type(ri_extra.handle)
      let collres = get_ri_gen_extra_collres(int(riType))
      if collres == null
        return

      let margin = float4(pair_door__checkMargin, pair_door__checkMargin, pair_door__checkMargin, 0.0)
      var extendedBox = collres.vFullBBox
      extendedBox.bmin -= margin
      extendedBox.bmax += margin

      var seed = int(uint(eid))
      let color = rnd_color(seed)
      set_cached_debug_lines_wtm(transform)
      draw_cached_debug_box(BBox3(extendedBox), color)

    end_draw_cached_debug_lines()


[console_cmd(name="unpaired_doors_log")]
def log_unpaired_doors()
  print("Potentially unpaired doors:")
  ecs::query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId;
                                          transform : float3x4;
                                          pair_door__eid : EntityId;
                                          pair_door__searchDist : float = 3.0)
    if pair_door__eid != INVALID_ENTITY_ID
      return

    let bounding = BSphere3(transform[3], pair_door__searchDist)
    let found = find_entity_in_grid(ecs_hash("doors"), bounding, GridEntCheck POS) <| $(potentialPairEid : EntityId)
      if potentialPairEid == eid
        return false
      let pairEid = get_Eid(potentialPairEid, "pair_door__eid") ?? INVALID_ENTITY_ID
      return !pairEid

    if found != INVALID_ENTITY_ID
      return

    print("{transform[3]}")
