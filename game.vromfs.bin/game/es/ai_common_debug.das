options no_aot
require ecs
require BehNodes
require DagorConsole

[console_cmd(name="ai.print_nodes_names")]
def print_ai_nodes_names()
  find_query() <| $ [es] (beh_tree : BehaviourTree)
    beh_tree |> beh_tree_printDebugNames()
    return true
