require ecs
require ecs.safe
require ecs.common
require math.base
require WorldRenderer
require enlisted.events_enlisted
require DagorMath
require RiDestr
require fx
require DagorRandom
require DagorSystem
require ClipmapDecals
require PhysMat

def is_crater_part_valid_pos(part_pos : int2; part_grid_width : int)
  return part_pos.x >= 0 && part_pos.x < part_grid_width && part_pos.y >= 0 && part_pos.y < part_grid_width

def is_crater_part_available(available_parts_mask : uint64; part_grid_width : int; part_pos : int2)
  let partIndex = part_pos.x + part_pos.y * part_grid_width
  let partMask = (1ul << uint64(partIndex))
  return is_crater_part_valid_pos(part_pos, part_grid_width) && (available_parts_mask & partMask) == partMask

def make_crater_part_available(available_parts_mask : uint64; part_grid_width : int; part_pos : int2)
  let partIndex = part_pos.x + part_pos.y * part_grid_width
  let partMask = (1ul << uint64(partIndex))
  return is_crater_part_valid_pos(part_pos, part_grid_width) ? (available_parts_mask | partMask) : available_parts_mask

def make_outlined_available_crater_parts_for_decal(available_parts_mask : uint64; part_grid_width : int)
  var parts_mask = available_parts_mask
  for partIndexX in range(0, part_grid_width)
    for partIndexY in range(0, part_grid_width)
      let partPos = int2(partIndexX, partIndexY)
      if is_crater_part_available(available_parts_mask, part_grid_width, partPos)
        for offset in [[int2 int2(-1,-1); int2(-1, 1); int2(1, -1); int2(1, 1)]]
          parts_mask = parts_mask | make_crater_part_available(available_parts_mask, part_grid_width, partPos + offset)
  return parts_mask

[es(tag=render)]
def heightmap_change_invalidation_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  erase_grass(evt.pos, evt.outerRadius);
  invalidate_after_heightmap_change(BBox3(evt.pos, 2.0 * evt.outerRadius))

[es(tag=render, on_event=EventLevelLoaded)]
def terraform_crater_decals_init(evt : Event;
                                 bomb_crater_config__decalNames : StringList;
                                 bomb_crater_config__decalPhysmats : StringList;
                                 var bomb_crater_config__decalIds : IntList;
                                 var bomb_crater_config__decalPhysmatsIds : IntList)
  if length(bomb_crater_config__decalNames) != length(bomb_crater_config__decalPhysmats)
    logerr("bomb_crater_config__decalNames and bomb_crater_config__decalPhysmats have a different lengths!")
    return
  if empty(bomb_crater_config__decalNames) || empty(bomb_crater_config__decalPhysmats)
    logerr("bomb_crater_config__decalNames or bomb_crater_config__decalPhysmats is empty therefore crater decals will not work!")
    return

  for decalName, physmat in bomb_crater_config__decalNames, bomb_crater_config__decalPhysmats
    let decalId = get_clipmap_decal_id_by_name(string(decalName))
    if decalId < 0
      logerr("invalid decal name '{decalName}' in bomb_crater_config__decalNames")

    let matId = get_material_id(string(physmat))
    if matId < 0
      logerr("invalid physmat name '{physmat}' in bomb_crater_config__decalPhysmats")

    push(bomb_crater_config__decalIds, decalId)
    push(bomb_crater_config__decalPhysmatsIds, matId)


[es(tag=render)]
def terraform_crater_create_land_decal(evt : EventBombCraterTerraformed;
                                       bomb_crater_config__decalIds : IntList;
                                       bomb_crater_config__decalPhysmatsIds : IntList)
  erase_bullet_holes(evt.pos, evt.outerRadius)

  if empty(bomb_crater_config__decalIds)
    return

  let physmatIdx = find_index(bomb_crater_config__decalPhysmatsIds, evt.mainPhysmatId)
  let decalId = bomb_crater_config__decalIds?[physmatIdx] ?? bomb_crater_config__decalIds?[0] ?? -1
  if decalId < 0
    return

  let pos = evt.pos.xz
  let decalSize = float2(evt.outerRadius)
  let partsMask = make_outlined_available_crater_parts_for_decal(evt.availablePartsMask, evt.partsGridWidth)
  create_clipmap_decal(decalId, pos, rnd_float(0.0, PI * 2.0), decalSize, 0, false, partsMask, evt.partsGridWidth)

[es(tag=render)]
def create_smoke_emitter_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  var tm = scale_tm(evt.outerRadius)
  tm[3] = evt.pos
  createEntity("explosion_smoke_crater_effect") <| $(var init : ComponentsInitializer)
    set(init, "transform", tm)

[es(tag=render)]
def remove_puddles_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  remove_puddles_in_crater(evt.pos, evt.outerRadius)

[es(tag=render)]
def remove_visual_ri_on_terraform_bomb_crater_part(evt : EventBombCraterPartTerraformed)
  remove_ri_without_collision_in_radius(evt.partPos, evt.partRadius)