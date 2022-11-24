require ecs
require DagorDataBlock
require enlisted.game.es.enlisted_squad_common
require enlisted.game.es.bomb_site_common
require game.es.vehicle.vehicle_seats_common
require BehNodes
require EnlistedBehTree

[es(tag=server, no_order, REQUIRE=aiBombBehaviour)]
def on_squad_leader_use_bomb_es(act : UpdateStageInfoAct)
  query() <| $ [es] (squad__leader : EntityId;
                     squad__ownerPlayer : EntityId)
    if !has(squad__ownerPlayer, "botAiEnabler")
      return

    query(squad__leader) <| $ [es] (beh_tree__bombSiteInRadiusDistSqr : float;
                                    transform aka agent_transform : float3x4;
                                    beh_tree__data__orderReq : string;
                                    beh_tree__data__plantBombReq : string;
                                    beh_tree__data__defuseBombReq : string;
                                    beh_tree__isInTrainBeh : bool;
                                    var beh_tree__useBombResetTrigger : bool&;
                                    var beh_tree__refs__behaviour : das_string&;
                                    var beh_tree__refs__orderType : das_string&;
                                    var beh_tree__useBomb : bool&;
                                    var beh_tree : BehaviourTree&;
                                    var beh_tree__latencyLoadBlackBoard : Object?)
      if beh_tree__useBomb || beh_tree__isInTrainBeh
        return

      query() <| $ [es(REQUIRE=bombSite)] (eid : EntityId;
                                           transform aka bomb_transform : float3x4)
        if distance_sq(agent_transform[3], bomb_transform[3]) < beh_tree__bombSiteInRadiusDistSqr
          if can_plant_bomb(eid, squad__leader)
            beh_tree__useBombResetTrigger = true
            beh_tree__useBomb = true
            beh_tree__refs__behaviour := beh_tree__data__orderReq
            beh_tree__refs__orderType := beh_tree__data__plantBombReq

            reload_squad_mate_beh_tree(squad__leader)

            if beh_tree__latencyLoadBlackBoard != null
              *beh_tree__latencyLoadBlackBoard |> set("bombSiteEid", int(uint(eid)))
              *beh_tree__latencyLoadBlackBoard |> set("bombSitePos", bomb_transform[3])
            beh_tree.blackBoard |> set("bombSiteEid", int(uint(eid)))
            beh_tree.blackBoard |> set("bombSitePos", bomb_transform[3])

          if can_defuse_bomb(eid, squad__leader)
            beh_tree__useBombResetTrigger = true
            beh_tree__useBomb  = true
            beh_tree__refs__behaviour := beh_tree__data__orderReq
            beh_tree__refs__orderType := beh_tree__data__defuseBombReq

            reload_squad_mate_beh_tree(squad__leader)

            if beh_tree__latencyLoadBlackBoard != null
              *beh_tree__latencyLoadBlackBoard |> set("bombSiteEid", int(uint(eid)))
              *beh_tree__latencyLoadBlackBoard |> set("bombSitePos", bomb_transform[3])
            beh_tree.blackBoard |> set("bombSiteEid", int(uint(eid)))
            beh_tree.blackBoard |> set("bombSitePos", bomb_transform[3])

[es(tag=server, track=beh_tree__useBombResetTrigger)]
def on_squad_leader_using_bomb_es(evt : Event;
                                  eid : EntityId;
                                  beh_tree__useBombResetTrigger : bool)
  if beh_tree__useBombResetTrigger
    return

  reset_squad_mate_behaviour(eid)

[es(on_event=EventLevelLoaded)]
def create_ai_bomb_beh_on_level_loaded(evt : Event)
  find_query() <| $ [es] (walker_agent__aiBombBehaviourEntity : string)
    createEntity(walker_agent__aiBombBehaviourEntity)
    return true
