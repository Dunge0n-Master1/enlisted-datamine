require ecs
require ecs.safe
require ecs.common
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
require PhysMat

[es(tag=render)]
def digging_heightmap_change_invalidation_on_terraform(evt : CmdDig)
  erase_grass(evt.pos, evt.radius);
  invalidate_after_heightmap_change(BBox3(evt.pos, 2.0 * evt.radius))

[es(tag=render)]
def remove_ri_on_terraform(evt : CmdDig)
  remove_ri_without_collision_in_radius(evt.pos, evt.radius)

[es(tag=render)]
def start_dig_fx_es(evt : CmdDig;
                    digging_config__fxName : string;
                    digging_config__fxScale : float;
                    digging_config__fxUpDirectionWeight : float)
  query(evt.diggerEid) <| $ [es] (transform : float3x4)
    let humanUpQuat = float4(dir_to_quat(transform[1]))
    let humanLeftQuat = float4(dir_to_quat(transform[2]))
    let quat = normalize(lerp(humanLeftQuat, humanUpQuat, float4(digging_config__fxUpDirectionWeight)))

    var tm : float3x4
    make_tm(quat(quat), evt.pos, tm)
    swap(tm[0], tm[1])

    start_effect(digging_config__fxName, tm, IDENT_TM) <| $(var fx : AcesEffect)
      fx |> setFxScale(digging_config__fxScale)

[es(tag=render, on_event=EventLevelLoaded)]
def human_dig_decals_init(evt : Event;
                          digging_config__decalNames : StringList;
                          digging_config__decalPhysmats : StringList;
                          var digging_config__decalIds : IntList;
                          var digging_config__decalPhysmatsIds : IntList)
  if length(digging_config__decalNames) != length(digging_config__decalPhysmats)
    logerr("digging_config__decalNames and digging_config__decalPhysmats have a different lengths!")
    return

  for decalName, physmat in digging_config__decalNames, digging_config__decalPhysmats
    let decalId = get_clipmap_decal_id_by_name(string(decalName))
    if decalId < 0
      logerr("invalid decal name '{decalName}' in digging_config__decalNames")

    let matId = get_material_id(string(physmat))
    if matId < 0
      logerr("invalid physmat name '{physmat}' in digging_config__decalPhysmats")

    push(digging_config__decalIds, decalId)
    push(digging_config__decalPhysmatsIds, matId)

[es(tag=render)]
def human_dig_decal_create_on_digging(evt : CmdDig;
                                      digging_config__decalIds : IntList;
                                      digging_config__decalPhysmatsIds : IntList;
                                      digging_config__decalScale : float)
  if length(digging_config__decalIds) <= 0
    return

  let physmatIdx = find_index(digging_config__decalPhysmatsIds, evt.matId)
  let decalId = digging_config__decalIds?[physmatIdx] ?? digging_config__decalIds[0]
  if decalId < 0
    return

  let pos = evt.pos.xz
  let decalSize = float2(evt.radius) * digging_config__decalScale
  create_clipmap_decal(decalId, pos, rnd_float(0.0, PI * 2.0), decalSize, 0, false, -1ul, 1)

[es(tag=render)]
def human_dig_remove_puddles_on_digging(evt : CmdDig; digging_config__removePuddlesRadiusScale : float)
  remove_puddles_in_crater(evt.pos, evt.radius * digging_config__removePuddlesRadiusScale)
