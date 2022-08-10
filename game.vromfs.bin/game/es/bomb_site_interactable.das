require ecs
require math.base
require game.utils.hero
require game.utils.team
require player
require common_shooter.es.use_query_params_common
require DagorMath
require CollRes
require Dacoll
require RendInst
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=hero, REQUIRE_NOT=deadEntity, after=hero_human_pre_use_object_es, before=hero_human_final_use_object_sync)]
def on_looking_at_bomb_site_ri(act : ParallelUpdateFrameDelayed;
                               eid : EntityId;
                               team : int;
                               human_use_object__useDist : float;
                               human_use_bomb_site__checkInterval : float;
                               human_use_bomb_site__traceSafeOffset : float;
                               var human_use_bomb_site__lastSelected : EntityId&;
                               var human_use_bomb_site__nextCheckTime : float&;
                               var human_use_object__selectedObject : EntityId&;
                               var human_use_object__lookAtSelected : bool&)
  if human_use_object__selectedObject != INVALID_ENTITY_ID
    return
  if act.curTime < human_use_bomb_site__nextCheckTime
    human_use_object__selectedObject = human_use_bomb_site__lastSelected
    return
  human_use_bomb_site__nextCheckTime = act.curTime + human_use_bomb_site__checkInterval
  human_use_bomb_site__lastSelected = INVALID_ENTITY_ID
  let heroEid = eid
  let useParams = get_use_query_params(get_controlled_hero())
  if !useParams.canUse
    return
  find_query() <| $ [es] (eid : EntityId;
                          active : bool = true;
                          transform : float3x4;
                          bomb_site__operator : EntityId;
                          bomb_site__plantingTeam : int;
                          bomb_site__isBombPlanted : bool;
                          bomb_site__canResetProgressByInteraction : bool;
                          bomb_site__maxDist : float;
                          ri_extra : RiExtraComponent)
    let canTeamInteract = (is_teams_friendly(team, bomb_site__plantingTeam)
       ? !bomb_site__isBombPlanted
       : (bomb_site__isBombPlanted || bomb_site__canResetProgressByInteraction))
    if active && canTeamInteract && (!bomb_site__operator || bomb_site__operator == heroEid)
      let objPos = transform[3]
      if length_sq(objPos - useParams.pos) > square(bomb_site__maxDist)
        return false

      let riType = handle_to_ri_type(ri_extra.handle)
      let riCollres = get_ri_gen_extra_collres(int(riType))
      if riCollres == null
        return false

      var t = human_use_object__useDist
      var norm : float3
      var matId : int
      if transform[3].y > useParams.pos.y
        return false
      if collres_traceray(*riCollres, transform, useParams.pos, useParams.dir, t, norm, matId)
        var checkDist = max(0.f, t - human_use_bomb_site__traceSafeOffset)
        if !traceray_normalized(useParams.pos, useParams.dir, checkDist, norm)
          human_use_object__selectedObject = eid
          human_use_object__lookAtSelected = true
          human_use_bomb_site__lastSelected = human_use_object__selectedObject

    return !!human_use_object__selectedObject

[es(tag=(ui, render, gameClient), on_appear)]
def human_use_action_bomb_site(evt : Event;
                               bomb_site__plantingTeam : int;
                               bomb_site__usePromptPlant : string;
                               bomb_site__usePromptDefuse : string;
                               var item__customUsePrompt : das_string&)
  let playerTeam = get_int(get_local_player_eid(), "team") ?? TEAM_UNASSIGNED
  item__customUsePrompt := is_teams_friendly(playerTeam, bomb_site__plantingTeam) ? bomb_site__usePromptPlant : bomb_site__usePromptDefuse