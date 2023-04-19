options no_global_variables = false
require ecs
require BehNodes
require walkerai
require DngWalkerai
require game.es.squad_order_common

var // these variables keep constant values that don't change at runtime (after set), variables for non constant values are prohibited
  PERSONAL_ORDER_REACTION_ID : int
  PLANT_BOMB_ORDER_REACTION_ID : int
  DEFUSE_BOMB_ORDER_REACTION_ID : int

[register_beh_nodes]
def register_nodes()
  PERSONAL_ORDER_REACTION_ID = walkerai::register_reaction("onPersonalOrder")
  PLANT_BOMB_ORDER_REACTION_ID = walkerai::register_reaction("onPlantBombOrder")
  DEFUSE_BOMB_ORDER_REACTION_ID = walkerai::register_reaction("onDefuseBombOrder")

[es(tag=server, track=squad_member__isPersonalOrder, REQUIRE=squad_member__isPersonalOrder)]
def on_make_squad_mate_personal_order(evt : Event; var beh_tree : BehaviourTree&)
  beh_tree |> beh_tree_react(PERSONAL_ORDER_REACTION_ID, 0f)

[es(tag=server, track=squad_member__orderType, REQUIRE=squad_member__orderType)]
def on_change_squad_mate_personal_order(evt : Event;
                                        squad_member__isPersonalOrder : bool;
                                        var beh_tree : BehaviourTree&)
  if squad_member__isPersonalOrder
    beh_tree |> beh_tree_react(PERSONAL_ORDER_REACTION_ID, 0f)

[es(tag=server, track=squad_member__orderType)]
def on_plant_or_defuse_bomb_order(evt : Event; squad_member__orderType : int; var beh_tree : BehaviourTree&)
  if squad_member__orderType == int(SquadMateOrder ESMO_PLANT_BOMB)
    beh_tree |> beh_tree_react(PLANT_BOMB_ORDER_REACTION_ID, 0f)
  elif squad_member__orderType == int(SquadMateOrder ESMO_DEFUSE_BOMB)
    beh_tree |> beh_tree_react(DEFUSE_BOMB_ORDER_REACTION_ID, 0f)