require ecs
require WorldRenderer
require enlisted.events_enlisted
require DagorMath
require RiDestr
require fx
require DagorRandom
require DagorSystem
require ClipmapDecals

[es(tag=render)]
def heightmap_change_invalidation_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  erase_grass(evt.pos, evt.outerRadius);
  invalidate_after_heightmap_change(BBox3(evt.pos, 2.0 * evt.outerRadius))

[es(tag=render, on_event=EventLevelLoaded)]
def terraform_bomb_crater_init_decal(evt : Event;
                                     bomb_crater_config__decalName : string;
                                     var bomb_crater_config__decalId : int&)
  var decalName = bomb_crater_config__decalName
  query() <| $ [es] (bomb_crater_config_override__decalName : string)
    decalName = bomb_crater_config_override__decalName

  bomb_crater_config__decalId = get_clipmap_decal_id_by_name(decalName)
  if bomb_crater_config__decalId < 0
    logerr("invalid name '{bomb_crater_config__decalName}' of bomb crater decal (bomb_crater_config__decalName)")

[es(tag=render)]
def create_land_decal_on_terraform_bomb_crater(evt : EventBombCraterTerraformed; bomb_crater_config__decalId : int)
  erase_bullet_holes(evt.pos, evt.outerRadius)

  if bomb_crater_config__decalId < 0
    return
  let pos = evt.pos.xz
  let decalSize = float2(evt.outerRadius)
  create_clipmap_decal(bomb_crater_config__decalId, pos, rnd_float(0.0, PI * 2.0), decalSize, 0, false,
                       evt.availablePartsMask, evt.partsGridWidth)

[es(tag=render)]
def remove_puddles_on_terraform_bomb_crater(evt : EventBombCraterTerraformed)
  remove_puddles_in_crater(evt.pos, evt.outerRadius)

[es(tag=render)]
def remove_visual_ri_on_terraform_bomb_crater_part(evt : EventBombCraterPartTerraformed)
  remove_ri_without_collision_in_radius(evt.partPos, evt.partRadius)