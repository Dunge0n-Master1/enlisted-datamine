require ecs
require Action
require EnlistedHuman
require HumanPhys


def block_sprint_common(eid : ecs::EntityId;
                        var human_net_phys : HumanActor;
                        human_weap__throwMode : bool;
                        burning__isPuttingOut : bool)
  let blocked = human_weap__throwMode || does_action_block_sprint(eid) || burning__isPuttingOut
  human_phys_state_set_block_sprint(human_net_phys.phys.currentState, blocked)

[es(tag=gameClient, REQUIRE=hero, no_order)]
def human_block_sprint_client_es(info : UpdateStageInfoAct;
                                 eid : ecs::EntityId;
                                 var human_net_phys : HumanActor;
                                 human_weap__throwMode : bool;
                                 burning__isPuttingOut : bool = false)
  block_sprint_common(eid, human_net_phys, human_weap__throwMode, burning__isPuttingOut)

[es(tag=server, REQUIRE_NOT=hero, no_order)]
def human_block_sprint_sever_es(info : UpdateStageInfoAct;
                                eid : ecs::EntityId;
                                var human_net_phys : HumanActor;
                                human_weap__throwMode : bool;
                                burning__isPuttingOut : bool = false)
  block_sprint_common(eid, human_net_phys, human_weap__throwMode, burning__isPuttingOut)