require ecs
require math.base
require DngHuman
require game.es.events

[es(REQUIRE_NOT=deadEntity)]
def human_lean_controls(evt : CmdPostPhysUpdate;
                        human_net_phys : HumanActor;
                        var human_net_phys__wishLean : float&)
  assume phys = human_net_phys.phys

  if !phys.currentState.isControllable
    human_net_phys__wishLean = 0.
    return

  let ctLean = clamp(phys.appliedCT.leanPosition, -1., 1.)
  human_net_phys__wishLean = ctLean * phys.leanDegrees

[es(REQUIRE_NOT=deadEntity, after=human_lean_controls)]
def human_lean_apply(evt : CmdPostPhysUpdate;
                     human_net_phys__leanSpeed : float = 180.0;
                     human_net_phys__wishLean : float;
                     var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState

  currentState.leanPosition = move_to(currentState.leanPosition, human_net_phys__wishLean, evt.dt, human_net_phys__leanSpeed)
