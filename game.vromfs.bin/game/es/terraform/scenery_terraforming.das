require ecs
require DagorMath
require enlisted.events_enlisted
require game.es.terraform.scenery_terraforming_common
require terraform

def apply_terraforming(elevs : Array; egras : Array)
  find_query() <| $ [es] (var terraform : TerraformComponent)
    var bbox = BBox3(float3(0.0, 0.0, 0.0), 0.0)

    // first apply RI damage (as part of grass erasers) for unchanged heightmap
    //
    if length(egras) > 0
      for egra in egras
        let data = get_Point3(egra) ?? float3(0.0, 0.0, 0.0)
        let pos = float3(data.x, 0.0, data.y)
        let rad = data.z
        apply_erase_grass(pos, rad)

    // then apply heightmap elevations
    //
    if length(elevs) > 0
      let first = get_Point4(elevs[0]) ?? float4(0.0, 0.0, 0.0, 0.0)
      bbox = BBox3(float3(first.x, MIN_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, first.y), 2.0 * first.z)
      for elev in elevs
        let data = get_Point4(elev) ?? float4(0.0, 0.0, 0.0, 0.0)
        let pos = float3(data.x, MAX_TERRAFORMING_INVALIDATE_HMAP_HEIGHT, data.y)
        let rad = data.z
        let alt = data.w
        apply_elevation(terraform, bbox, pos, rad, alt)

    broadcastEvent([[CmdTerraUpdateRender hmapBoxMin=bbox.boxMin, hmapBoxMax=bbox.boxMax, egrasBase=0, egrasNum=length(egras)]])
    return true

[es(tag=server, after=terraform_init_es_event_handler, on_event=EventLevelLoaded)]
def terraforming_apply_server_es(evt : Event;
                                 elevs : Array;
                                 egras : Array)
  apply_terraforming(elevs, egras)

[es(tag=netClient, after=terraform_init_es_event_handler, on_event=EventLevelLoaded)]
def terraforming_apply_netclient_es(evt : Event;
                                    elevs : Array;
                                    egras : Array)
  apply_terraforming(elevs, egras)
