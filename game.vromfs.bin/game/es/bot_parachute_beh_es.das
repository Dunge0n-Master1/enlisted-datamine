require ecs
require DngBehTree

[es(tag=server, REQUIRE=human_freefall__affect, no_order)]
def bot_free_fall_beh_tree_update_es(info : UpdateStageInfoAct; game_effect__attachedTo : EntityId)
  query(game_effect__attachedTo) <| $ [es] (beh_tree__enabled : bool;
                                            beh_tree__data__parachuteBeh : string;
                                            var beh_tree__isFreefallOrParachute : bool&;
                                            var beh_tree__refs__behaviour : das_string&)
    if !beh_tree__enabled || beh_tree__isFreefallOrParachute
      return
    beh_tree__isFreefallOrParachute = true
    beh_tree__refs__behaviour := beh_tree__data__parachuteBeh
    DngBehTree::load_beh_tree_from_ecs(game_effect__attachedTo)

[es(tag=server, REQUIRE=parachuteDeployed, no_order)]
def bot_parachute_beh_tree_update_es(info : UpdateStageInfoAct;
                                     eid : EntityId;
                                     beh_tree__enabled : bool;
                                     beh_tree__data__parachuteBeh : string;
                                     var beh_tree__isFreefallOrParachute : bool&;
                                     var beh_tree__refs__behaviour : das_string&)
  if !beh_tree__enabled || beh_tree__isFreefallOrParachute
    return
  beh_tree__isFreefallOrParachute = true
  beh_tree__refs__behaviour := beh_tree__data__parachuteBeh
  DngBehTree::load_beh_tree_from_ecs(eid)
