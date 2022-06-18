require ecs
require DagorMath
require DagorRandom
require game.utils.team
require math

struct MeanPos
  eid : EntityId
  team : int
  pos : float3
  accumPos : float3
  amountOfPoints : int

[es(tag=server, after=human_phys_es)]
def kmeans_enemy_pos(act : UpdateStageInfoAct)
  var posCache : array<MeanPos>
  query <| $ [es] (eid : EntityId;
                   mean_pos__pos : float3&;
                   mean_pos__team : int)
    posCache |> emplace([[MeanPos eid=eid, team=mean_pos__team, pos=mean_pos__pos]])
  if posCache |> empty()
    return
  var enemyPoints : array<tuple<team : int; offset : float3> >
  query <| $ [es] (isAlive, countAsAlive : bool; transform : float3x4;
                   team : int)
    if !isAlive || !countAsAlive
      return
    var closest = -1
    var bestDist = FLT_MAX
    enemyPoints |> emplace([[auto team, transform[3]]])
    for pos, i in posCache, iter_range(posCache)
      if pos.team != TEAM_UNASSIGNED && team != pos.team
        continue
      let dist = length_sq(pos.pos - transform[3])
      if dist < bestDist
        closest = i
        bestDist = dist
    if closest > -1
      posCache[closest].accumPos += transform[3]
      posCache[closest].amountOfPoints++
  for pos in posCache
    if pos.amountOfPoints > 0
      let meanPos = pos.accumPos * safeinv(float(pos.amountOfPoints))
      query(pos.eid) <| $ [es] (var mean_pos__pos : float3&)
        mean_pos__pos = meanPos
    elif !(enemyPoints |> empty()) // assign to random point
      var countPoints = enemyPoints |> length()
      if pos.team != TEAM_UNASSIGNED
        for pt in enemyPoints
          if pt.team == pos.team
            countPoints += 1
      if countPoints > 0
        var rndIdx = grnd() % countPoints
        for pt in enemyPoints
          if pt.team != pos.team
            continue
          if rndIdx == 0
            query(pos.eid) <| $ [es] (var mean_pos__pos : float3&)
              mean_pos__pos = pt.offset
            break
          rndIdx--