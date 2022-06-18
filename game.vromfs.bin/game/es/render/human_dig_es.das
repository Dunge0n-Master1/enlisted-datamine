require ecs
require terraform
require WorldRenderer
require enlisted.events_enlisted
require DagorMath
require DagorSystem
require RiDestr
require fx
require math.base
require ClipmapDecals
require DagorRandom

[es(tag=render)]
def digging_heightmap_change_invalidation_on_terraform(evt : CmdTerraform)
  erase_grass(evt.pos, evt.radius);
  invalidate_after_heightmap_change(BBox3(evt.pos, 2.0 * evt.radius))

[es(tag=render)]
def remove_ri_on_terraform(evt : CmdTerraform)
  remove_ri_without_collision_in_radius(evt.pos, evt.radius)

[es(tag=render, REQUIRE=watchedByPlr)]
def start_dig_fx_es(evt : CmdTerraform;
                    transform : float3x4;
                    digging_fx__name : string;
                    digging_fx__scale : float;
                    digging_fx__upDirectionWeight : float)
  let humanUpQuat = float4(dir_to_quat(transform[1]))
  let humanLeftQuat = float4(dir_to_quat(transform[2]))
  let quat = normalize(lerp(humanLeftQuat, humanUpQuat, float4(digging_fx__upDirectionWeight)))

  var tm : float3x4
  make_tm(quat(quat), evt.pos, tm)
  swap(tm[0], tm[1])

  start_effect(digging_fx__name, tm, IDENT_TM) <| $(var fx : AcesEffect)
    fx |> setFxScale(digging_fx__scale)

[es(tag=render, on_appear)]
def human_dig_decal_init(evt : Event;
                         digging__decalName : string;
                         var digging__decalId : int&)
  digging__decalId = get_clipmap_decal_id_by_name(digging__decalName)
  if digging__decalId < 0
    logerr("invalid name '{digging__decalName}' of digging decal (digging__decalName)")

[es(tag=render, REQUIRE=watchedByPlr)]
def human_dig_decal_create_on_digging(evt : CmdTerraform; digging__decalId : int)
  if digging__decalId < 0
    return

  let pos = evt.pos.xz
  let decalSize = float2(evt.radius)
  create_clipmap_decal(digging__decalId, pos, rnd_float(0.0, PI * 2.0), decalSize, 0, false, -1ul, 1)
