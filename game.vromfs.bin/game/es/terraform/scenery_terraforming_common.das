module scenery_terraforming_common shared
require ecs
require DagorMath
require terraform
require DagorSystem
require RendInst
require Dacoll

let
  MIN_TERRAFORMING_INVALIDATE_HMAP_HEIGHT = -10000.0
  MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT =  10000.0

def apply_elevation(var terraform : TerraformComponent; var bbox : BBox3;
                    pos : float3; radius : float; alt : float)
  if radius > 0.0 && alt != 0.0
    let elevatePos = pos.xz
    terraform |> terraform_queueElevationChange(elevatePos, radius, alt)
    bbox3_add(bbox, BBox3(pos, 2.0 * radius))
    // NOTE: invalidate_after_heightmap_change() applied in CmdTerraUpdateRender

def destroy_damage_ri(pos : float3; radius : float)
  if radius > 0.0
    let hmapPos = float2(pos.x, pos.z)
    let height = traceht_hmap(hmapPos)
    let sphPos = float3(pos.x, height, pos.z)
    let sph = BSphere3(sphPos, radius)
    let axis : float3
    rendinst_doRIGenDamage(sph, get_dagor_frame_no(), axis)

def apply_erase_grass(pos : float3; radius : float)
  if radius > 0.0
    destroy_damage_ri(pos, radius * 2.0)
    // NOTE: erase_grass() applied in CmdTerraUpdateRender
