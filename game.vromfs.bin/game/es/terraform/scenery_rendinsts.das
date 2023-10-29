require ecs
require app
require strings
require DagorSystem
require enlisted.events_enlisted
require game.es.terraform.scenery_rendinsts_common
require game.es.ri_double_doors_common
require ecs.ecs_template


def rirmv_log(start_time : int64; msg : string)
  let elapsedTime = float(get_time_usec(start_time)) * 0.001
  let frameNo = int(get_dagor_frame_no())
  print("rirmv_log: ({format("%.2f", elapsedTime)}ms/{frameNo}) {msg}")

def remove_rendinsts(rmv_list : Array)
  let startTime = ref_time_ticks()

  var count = 0
  for rmv in rmv_list
    let obj = get_ecs_object(rmv)
    if obj == null
      continue
    let tm = get_TMatrix(*obj, "tm")
    if tm == null
      continue
    let name = get_string(*obj, "name", "")
    if !remove_rendinst(*tm, name)
      print("rirmv_log: failed to remove {name} at {(*tm)[3]}")
    else
      ++count

  rirmv_log(startTime, "removed {count}/{length(rmv_list)} instances")


[es(tag=server, on_event=EventLevelLoaded, before=terraforming_apply_server_es)]
def scenery_rendinsts_removes_server_apply_es(evt : Event;
                                              rirmv : Array;
                                              riunb : Array)
  remove_rendinsts(rirmv)
  remove_rendinsts(riunb)

[es(tag=netClient, on_event=EventLevelLoaded, before=terraforming_apply_netclient_es)]
def scenery_rendinsts_removes_netclient_apply_es(evt : Event;
                                                 rirmv : Array;
                                                 riunb : Array)
  remove_rendinsts(rirmv)
  remove_rendinsts(riunb)


[es(tag=server, on_appear)]
def scenery_rendinsts_force_replicate_door_tm(evt : Event;
                                              transform : float3x4;
                                              var ri_replicateDoorTm : float3x4&)
  ri_replicateDoorTm = transform

[es(tag=netClient, on_appear, on_event=EventRendinstsLoaded, after=riextra_create_es)]
def scenery_rendinsts_apply_replicated_door_tm(evt : Event;
                                               ri_replicateDoorTm : float3x4;
                                               var initialTransform : float3x4&;
                                               var transform : float3x4&)
  initialTransform = ri_replicateDoorTm
  transform = initialTransform


[ecs_template]
struct scenery_rendinsts_connect_doors
  nonCreatableObj : bool = true
  scenery_rendinsts_connect_doors__wait : int

[es(on_appear, REQUIRE=(isDoor, clonedRIDoorTag), after=scenery_rendinsts_apply_replicated_door_tm)]
def scenery_rendinsts_pair_unbaked_door_ri(evt : Event)
  let alreadyCreated = find_query() <| $ [es(REQUIRE=scenery_rendinsts_connect_doors__wait)] (var scenery_rendinsts_connect_doors__wait : int&)
    scenery_rendinsts_connect_doors__wait = 10
    return true
  if alreadyCreated
    return
  createEntity("scenery_rendinsts_connect_doors") <| $(var init : ComponentsInitializer)
    set(init, "scenery_rendinsts_connect_doors__wait", 10)

[es(no_order)]
def scenery_rendinsts_connect_doors(info : UpdateStageInfoAct;
                                    eid : EntityId;
                                    var scenery_rendinsts_connect_doors__wait : int&)
  if scenery_rendinsts_connect_doors__wait > 0
    scenery_rendinsts_connect_doors__wait -= 1
    return
  destroyEntity(eid)
  query() <| $ [es(REQUIRE=isDoor)] (eid : EntityId)
    pair_riextra_door(eid)
