require ecs
require ecs.common
require game.es.respawn_base_common
require enlisted.events_enlisted
require math.base

[es(tag=gameClient, track=paratroopers_target_points)]
def paratroopers_target_icons_counter_es(evt : Event;
                                         counter_team : int;
                                         paratroopers_target_points : Point3List;
                                         paratroopers_target_points__connectDistSq : float;
                                         paratroopers_target_points__iconsTypename : string;
                                         paratroopers_target_points__heightDecrease : float;
                                         var paratroopers_target_points__icons : Point3List;
                                         var paratroopers_target_points__iconsCounters : IntList)
  clear(paratroopers_target_points__icons)
  clear(paratroopers_target_points__iconsCounters)
  for point in paratroopers_target_points
    var pointConnected = false
    for addedPoint, pointIndex in paratroopers_target_points__icons, iter_range(paratroopers_target_points__icons)
      if distance_sq(point, addedPoint) < paratroopers_target_points__connectDistSq
        paratroopers_target_points__iconsCounters[pointIndex] += 1
        pointConnected = true
        break
    if !pointConnected
      paratroopers_target_points__icons |> push(point)
      paratroopers_target_points__iconsCounters |> push(1)
  query() <| $ [es] (respawnIconType : string;
                     eid : EntityId;
                     team : int;
                     respawn_icon__active : bool;
                     transform : float3x4;
                     var respawn_icon__playersCount : int&)
    if team != counter_team || respawnIconType != paratroopers_target_points__iconsTypename || respawn_icon__active
      return
    let index = find_index(paratroopers_target_points__icons, transform[3])
    if index == -1
      destroyEntity(eid)
    else
      respawn_icon__playersCount = paratroopers_target_points__iconsCounters[index] > 1 ? paratroopers_target_points__iconsCounters[index] : 0
      erase(paratroopers_target_points__iconsCounters, index)
      erase(paratroopers_target_points__icons, index)
  for newIconPos, playersCount in paratroopers_target_points__icons, paratroopers_target_points__iconsCounters
    var tm = IDENT_TM
    tm[3] = newIconPos
    tm[3][1] += paratroopers_target_points__heightDecrease
    create_respawn_icon_with_params(tm, -2, paratroopers_target_points__iconsTypename, counter_team, playersCount > 1 ? playersCount : 0, false)

[es(tag=server)]
def paratroopers_target_icons_lifetime_es(info : ParallelUpdateFrameDelayed;
                                          paratroopers_target_points__checkPeriod : float;
                                          var paratroopers_target_points__checkTime : float&;
                                          var paratroopers_target_points : Point3List;
                                          var paratroopers_target_points__eids : EidList;
                                          var paratroopers_target_points__disappearanceTime : FloatList)
  if info.curTime < paratroopers_target_points__checkTime
    return
  paratroopers_target_points__checkTime = info.curTime + paratroopers_target_points__checkPeriod
  let startLength = length(paratroopers_target_points)
  for index in range(startLength)
    let reverseIndex = startLength - 1 - index
    if paratroopers_target_points__disappearanceTime[reverseIndex] < info.curTime
      erase(paratroopers_target_points__disappearanceTime, reverseIndex)
      erase(paratroopers_target_points, reverseIndex)
      erase(paratroopers_target_points__eids, reverseIndex)

[es(tag=server, track=respawner__enabled)]
def delete_paratroopers_target_points_after_players_death(evt : Event;
                                                          team : int;
                                                          respawner__enabled : bool;
                                                          eid : EntityId)
  if respawner__enabled
    query() <| $ [es] (counter_team : int;
                       var paratroopers_target_points__disappearanceTime : FloatList;
                       var paratroopers_target_points__eids : EidList;
                       var paratroopers_target_points : Point3List)
      if team == counter_team
        let index = find_index(paratroopers_target_points__eids, eid)
        if index != -1
          erase(paratroopers_target_points, index)
          erase(paratroopers_target_points__disappearanceTime, index)
          erase(paratroopers_target_points__eids, index)
