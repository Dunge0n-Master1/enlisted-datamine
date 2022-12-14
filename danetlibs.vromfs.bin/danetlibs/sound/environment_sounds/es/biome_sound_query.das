require ecs
require soundSystem
require landMesh
require DagorMath
require DagorSystem
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, on_appear)]
def biome_sound_query_appear(evt : Event;
                             biome_sound_query__biomeNames : StringList;
                             var biome_sound_query__values : Point3List;
                             var biome_sound_query__id : int&)
  assert(length(biome_sound_query__biomeNames) > 0)
  let count = length(biome_sound_query__biomeNames)
  biome_sound_query__values |> resize(count)
  for i in range(count)
    biome_sound_query__values[i] = float3(0., 0., 0.)
  biome_sound_query__id = -1


[es(tag=sound, no_order)]
def biome_sound_query_update(info : ParallelUpdateFrameDelayed;
                             biome_sound_query__range : float;
                             biome_sound_query__period : float;
                             biome_sound_query__varNames : StringList;
                             biome_sound_query__biomeNames : StringList;
                             var biome_sound_query__values : Point3List;
                             var biome_sound_query__id : int&;
                             var biome_sound_query__timeRange : float2&;
                             var biome_sound_query__nextQueryTime : float&)

  if biome_sound_query__id == -1 && info.curTime >= biome_sound_query__nextQueryTime
    biome_sound_query__id = biome_query_start(get_listener_pos(), biome_sound_query__range)
    biome_sound_query__nextQueryTime = info.curTime + biome_sound_query__period

  if biome_sound_query__id >= 0
    var result = BiomeQueryResult()
    let state = biome_query_result(biome_sound_query__id, result)

    if state != GpuReadbackResultState IN_PROGRESS
      biome_sound_query__nextQueryTime = info.curTime + biome_sound_query__period

      //logerr("state={state}   biome_sound_query__nextQueryTime={biome_sound_query__nextQueryTime}")

      if state == GpuReadbackResultState SUCCEEDED

        for idx in range(length(biome_sound_query__values))
          // .x - lerp from
          // .y - lerp to
          // .z - current
          biome_sound_query__values[idx].x = biome_sound_query__values[idx].z

          let groupId = get_biome_group_id(string(biome_sound_query__biomeNames[idx]))

          if groupId == result.mostFrequentBiomeGroupIndex
            biome_sound_query__values[idx].y = result.mostFrequentBiomeGroupWeight
          elif groupId == result.secondMostFrequentBiomeGroupIndex
            biome_sound_query__values[idx].y = result.secondMostFrequentBiomeGroupWeight
          else
            biome_sound_query__values[idx].y = 0.

        //sound_debug("{get_biome_group_name(result.mostFrequentBiomeGroupIndex)};
        //             {result.mostFrequentBiomeGroupWeight};
        //             {get_biome_group_name(result.secondMostFrequentBiomeGroupIndex)};
        //             {result.secondMostFrequentBiomeGroupWeight}")

        biome_sound_query__timeRange = float2(info.curTime, info.curTime + biome_sound_query__period)

      biome_sound_query__id = -1

  for idx in range(length(biome_sound_query__values))
    biome_sound_query__values[idx].z = cvt(info.curTime, biome_sound_query__timeRange.x, biome_sound_query__timeRange.y, biome_sound_query__values[idx].x, biome_sound_query__values[idx].y)
    set_var_global(string(biome_sound_query__varNames[idx]), biome_sound_query__values[idx].z)
