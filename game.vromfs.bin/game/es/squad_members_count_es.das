require ecs
require EnlistedWalkerai
require DagorRandom
require math
require math.base
require common_shooter.es.squad_common
require game.es.squad_order_common

let
  predefined_angles = [[ float[4]- HALF_PI; HALF_PI; -HALF_PI * 1.5f; HALF_PI * 1.5f ]]

def recalc_member_offset(member_idx : int; spread : float) : float3
  let ang = predefined_angles[member_idx % length(predefined_angles)]
  var sine, cosine : float
  sincos(ang, sine, cosine)
  let offset = float((member_idx / length(predefined_angles)) + 1) * spread
  return float3(cosine * offset, 0.0, sine * offset)

def squad_members_count_impl(dt : float;
                             eid : ecs::EntityId;
                             squad__leader : ecs::EntityId;
                             squad__orderType : int;
                             squad__regroupPos : float3;
                             squad__orderUseEntity : EntityId;
                             squad__shouldStandExactAtOrderPoint : bool;
                             squad__spreadAroundOrderPoint : float3;
                             squad__checkMembersTimeout : float;
                             var squad__numAliveMembers : int&;
                             var squad__numMembers : int&;
                             var squad__checkMembersTimer : float&)
  squad__checkMembersTimer -= dt
  if squad__checkMembersTimer <= 0.0f
    squad__checkMembersTimer = squad__checkMembersTimeout * (1.0f + gfrnd() * 0.5f)
    var numMembers = 0
    var numAliveMembers = 0
    let squad_eid = eid
    var shouldStandExactAtOrderPoint = squad__shouldStandExactAtOrderPoint && squad__orderType == int(SquadOrder ESO_DEFEND_POINT) && squad__orderUseEntity == INVALID_ENTITY_ID
    var members : array<EntityId>
    var posList : array<tuple<offset : float3; pos : float3>>
    ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member__squad : ecs::EntityId;
                            var squad_member__offset : float3&; isAlive : bool; isDowned = false)
      if squad_eid != squad_member__squad
        return
      numMembers++
      if isAlive
        numAliveMembers++
      if (eid != squad__leader) && !shouldStandExactAtOrderPoint
        push(members, eid)
      elif isAlive && !isDowned
        shouldStandExactAtOrderPoint = false
        squad_member__offset = float3(0.0, 0.0, 0.0)

    var numPoses = length(members)
    if numPoses % 2 != 0
      numPoses++
    for i in range(0, numPoses)
      let offset = recalc_member_offset(i, squad__spreadAroundOrderPoint.y)
      let pos = find_best_squad_pos(squad__leader, squad__orderType, squad__regroupPos,
          offset, squad__spreadAroundOrderPoint.x).p
      posList |> emplace([[auto offset, pos]])

    for member in members
      ecs::query(member) <| $ [es] (transform : float3x4; var squad_member__offset : float3&)
        var minDistSq : float = 0.0f
        var minI : int = -1
        for i in range(0, length(posList))
          let distSq = length_sq(posList[i].pos - transform[3])
          if minI < 0 || distSq < minDistSq
            minI = i
            minDistSq = distSq
        squad_member__offset = posList[minI].offset
        erase(posList, minI)

    squad__numMembers = max(squad__numMembers, numMembers)
    squad__numAliveMembers = numAliveMembers

[es(tag=server, before=(squad_es))]
def squad_members_count_es(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId; squad__leader : ecs::EntityId;
                           squad__orderType : int; squad__regroupPos : float3; squad__orderUseEntity : EntityId;
                           squad__shouldStandExactAtOrderPoint : bool; squad__spreadAroundOrderPoint : float3;
                           squad__checkMembersTimeout : float;
                           var squad__numAliveMembers : int&;
                           var squad__numMembers : int&; var squad__checkMembersTimer : float&)
  squad_members_count_impl(act.dt, eid, squad__leader, squad__orderType, squad__regroupPos, squad__orderUseEntity,
    squad__shouldStandExactAtOrderPoint, squad__spreadAroundOrderPoint,
    squad__checkMembersTimeout, squad__numAliveMembers, squad__numMembers, squad__checkMembersTimer)

[es(track=(squad__orderType, squad__leader, squad__orderUseEntity), tag=server, after=formation_order_change_squad_spread)]
def squad_members_count_trigger_es(evt : Event; eid : ecs::EntityId; squad__leader : ecs::EntityId;
                                   squad__orderType : int; squad__regroupPos : float3; squad__orderUseEntity : EntityId;
                                   squad__shouldStandExactAtOrderPoint : bool; squad__spreadAroundOrderPoint : float3;
                                   squad__checkMembersTimeout : float;
                                   var squad__numAliveMembers : int&;
                                   var squad__numMembers : int&; var squad__checkMembersTimer : float&)
  squad__checkMembersTimer = 0.0f
  squad_members_count_impl(0.0f, eid, squad__leader, squad__orderType, squad__regroupPos, squad__orderUseEntity,
    squad__shouldStandExactAtOrderPoint, squad__spreadAroundOrderPoint,
    squad__checkMembersTimeout, squad__numAliveMembers, squad__numMembers, squad__checkMembersTimer)
