require ecs
require app
require ecs.common
require game.es.events
require game.utils.team
require EnlistedWalkerai
require DagorConsole
require DagorDebug3D
require DagorRandom
require pathfinder


[es(tag=dev, tag=render, no_order)]
def bot_leader_nav_debug_draw_es(evt : UpdateStageInfoRenderDebug;
                                 bot_leader_nav_debug__draw : bool)
  if !bot_leader_nav_debug__draw
    return
  ecs::query() <| $ [es] (squad__leader : ecs::EntityId; squad__ownerPlayer : ecs::EntityId)
    var myTeam = TEAM_UNASSIGNED
    ecs::query(squad__ownerPlayer) <| $ [es(REQUIRE=playerIsBot)] (team : int)
      myTeam = team
    if myTeam != TEAM_UNASSIGNED
      ecs::query(squad__leader) <| $ [es] (isAlive : bool;
                                           isInVehicle : bool;
                                           transform : float3x4)
        if !isAlive || isInVehicle
          return
        draw_debug_sphere_buffered(transform[3], 2.0f, myTeam == 1 ? E3DCOLOR(0xFFFF0000) : E3DCOLOR(0xFF00FF00), 24, 1)

[es(tag=server, on_appear, track=squad__leader)]
def bot_leader_nav_create_es(evt : Event;
                             squad__allMembers : EidList;
                             squad__ownerPlayer : ecs::EntityId;
                             squad__leader : ecs::EntityId)
  var enable = has(squad__ownerPlayer, "playerIsBot")
  ecs::query() <| $ [es] (bot_leader_nav_debug__mode : int)
    if bot_leader_nav_debug__mode == 2
      enable = false
  if !enable
    return
  for memberEid in squad__allMembers
    if memberEid == squad__leader
      if !has(memberEid, "bot_leader_nav")
        addSubTemplate(memberEid, "bot_leader_nav")
    else
      removeSubTemplate(memberEid, "bot_leader_nav")

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def bot_leader_nav_destroy_es(evt : Event; team__id : int)
  ecs::query() <| $ [es] (squad__ownerPlayer : ecs::EntityId;
                          squad__leader : ecs::EntityId)
    ecs::query(squad__ownerPlayer) <| $ [es] (team : int)
      if (team__id == team)
        removeSubTemplate(squad__leader, "bot_leader_nav")

[es(tag=server, on_appear, REQUIRE=bot_leader_nav)]
def bot_leader_nav_created_es(evt : Event;
                              bot_leader_nav__ignoreChance : int;
                              bot_leader_nav__radiusMin : float2;
                              bot_leader_nav__radiusMax : float2;
                              bot_leader_nav__posOffsetMax : float;
                              var bot_leader_nav__radius : float2&;
                              var bot_leader_nav__posOffset : float&;
                              var bot_leader_nav__areaId : int&)
  // Don't create any nav areas once in a while.
  bot_leader_nav__areaId = (rnd_int(0, bot_leader_nav__ignoreChance) != 0) ? walker_agent_nav_allocAreaId() : 0
  bot_leader_nav__radius.x = rnd_float(bot_leader_nav__radiusMin.x, bot_leader_nav__radiusMax.x)
  bot_leader_nav__radius.y = rnd_float(bot_leader_nav__radiusMin.y, bot_leader_nav__radiusMax.y)
  // Pos offset is needed in order to avoid "sticking" of 2 bots with each other, i.e. if they start at the very same point
  // with similar nav areas they'll probably go the same direction since they both see the very same single area
  // located at their transform.
  bot_leader_nav__posOffset = rnd_float(0.0f, bot_leader_nav__posOffsetMax)

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=bot_leader_nav)]
def bot_leader_nav_destroyed_es(evt : Event;
                                eid : EntityId;
                                var walker_agent aka my_walker_agent : EntityAgent;
                                squad_member__squad : EntityId;
                                bot_leader_nav__areaId : int)
  var myTeam = TEAM_UNASSIGNED
  ecs::query(squad_member__squad) <| $ [es] (squad__ownerPlayer : ecs::EntityId)
    ecs::query(squad__ownerPlayer) <| $ [es] (team : int)
      myTeam = team
  if myTeam == TEAM_UNASSIGNED
    return
  let myAreaId = bot_leader_nav__areaId
  ecs::query() <| $ [es] (squad__leader : ecs::EntityId; squad__ownerPlayer : ecs::EntityId)
    if (squad__leader != eid)
      ecs::query(squad__ownerPlayer) <| $ [es(REQUIRE=playerIsBot)] (team : int)
        if team == myTeam
          ecs::query(squad__leader) <| $ [es] (var walker_agent : EntityAgent;
                                               bot_leader_nav__areaId : int)
            // I'm gone, remove my area from everyone else's on my team.
            // Remove everyone else's areas from me.
            walker_agent_nav_areaRemove(walker_agent, myAreaId)
            walker_agent_nav_areaRemove(my_walker_agent, bot_leader_nav__areaId)

[es(tag=server, no_order, REQUIRE=bot_leader_nav)]
def bot_leader_nav_update_es(info : ecs::UpdateStageInfoAct;
                             eid : EntityId;
                             var walker_agent aka my_walker_agent : EntityAgent;
                             transform : float3x4;
                             isAlive : bool;
                             isInVehicle : bool;
                             squad_member__squad : EntityId;
                             bot_leader_nav__areaId : int;
                             bot_leader_nav__areaPosThreshold : float;
                             bot_leader_nav__areaAngCosThreshold : float;
                             bot_leader_nav__radius : float2;
                             bot_leader_nav__posOffset : float;
                             bot_leader_nav__weight : float2;
                             bot_leader_nav__updateDelta : float;
                             var bot_leader_nav__lastUpdateTime : float&)
  if (info.curTime < bot_leader_nav__lastUpdateTime + bot_leader_nav__updateDelta)
    return
  bot_leader_nav__lastUpdateTime = info.curTime
  var myTeam = TEAM_UNASSIGNED
  ecs::query(squad_member__squad) <| $ [es] (squad__ownerPlayer : ecs::EntityId)
    ecs::query(squad__ownerPlayer) <| $ [es] (team : int)
      myTeam = team
  if myTeam == TEAM_UNASSIGNED
    return
  let myAreaId = bot_leader_nav__areaId
  let shouldUpdate = isAlive && !isInVehicle
  let pos = transform[3] + transform[0] * bot_leader_nav__posOffset
  ecs::query() <| $ [es] (squad__leader : ecs::EntityId; squad__ownerPlayer : ecs::EntityId)
    if (squad__leader != eid)
      ecs::query(squad__ownerPlayer) <| $ [es(REQUIRE=playerIsBot)] (team : int)
        if (myTeam == team)
          ecs::query(squad__leader) <| $ [es] (var walker_agent : EntityAgent; bot_leader_nav__areaId : int)
            if shouldUpdate
              walker_agent_nav_areaUpdateCylinder(walker_agent, myAreaId, pos, bot_leader_nav__radius,
                                                  bot_leader_nav__weight.x, bot_leader_nav__weight.y, true,
                                                  bot_leader_nav__areaPosThreshold, bot_leader_nav__areaAngCosThreshold)
            else
              // I'm not alive or in vehicle, remove my area from everyone else's on my team.
              // Remove everyone else's areas from me.
              walker_agent_nav_areaRemove(walker_agent, myAreaId)
              walker_agent_nav_areaRemove(my_walker_agent, bot_leader_nav__areaId)
