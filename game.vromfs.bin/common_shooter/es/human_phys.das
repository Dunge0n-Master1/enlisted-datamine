require ecs
require app
require EnlistedHuman
require HumanPhys
require DagorMath
require game.es.events

def is_in_air(human_phys__inAirTime : float)
  return human_phys__inAirTime != 0.

def was_in_air(human_phys__previousInAirTime : float; human_phys__inAirTimeThreshold : float)
  return human_phys__previousInAirTime > human_phys__inAirTimeThreshold

[es]
def human_phys_set_in_air_time(update : CmdPostPhysUpdate;
                               human_net_phys : HumanActor;
                               var human_phys__previousInAirTime : float&;
                               var human_phys__inAirTime : float&)
  assume currentState = human_net_phys.phys.currentState
  human_phys__previousInAirTime = human_phys__inAirTime
  let isInAir = (int(currentState.isInAirHistory) & 1) != 0 && (int(currentState.states) & int(StateFlag ST_SWIM)) == 0
  human_phys__inAirTime = isInAir ? (human_phys__inAirTime + update.dt) : 0.f

[es(after=human_phys_set_in_air_time)]
def human_phys_in_air_long(update : CmdPostPhysUpdate;
                           human_phys__afterJumpDampingTime : float;
                           human_phys__previousInAirTime : float;
                           human_phys__inAirTime : float;
                           human_phys__inAirTimeThreshold : float;
                           human_phys__inAirSpeedThreshold : float;
                           var human_phys__isInAirLong : bool&;
                           var human_net_phys : HumanActor&;
                           var human_phys__jumpEndTime : float&)
  assume currentState = human_net_phys.phys.currentState

  let wasInAir = was_in_air(human_phys__previousInAirTime, human_phys__inAirTimeThreshold)
  let isInAir = is_in_air(human_phys__inAirTime)

  if isInAir && wasInAir
    human_phys__isInAirLong = abs(currentState.velocity.y) > human_phys__inAirSpeedThreshold
  if !isInAir && human_phys__isInAirLong
    let physTime = float(update.tick) * update.dt
    human_phys__jumpEndTime = physTime
    human_phys__isInAirLong = false
    currentState.afterJumpDampingEndTime = human_phys__jumpEndTime + human_phys__afterJumpDampingTime

[es(after=human_phys_set_in_air_time)]
def human_phys_set_after_jump_damping(update : CmdPostPhysUpdate;
                                      human_phys__previousInAirTime : float;
                                      human_phys__inAirTime : float;
                                      human_phys__inAirTimeThreshold : float;
                                      human_phys__afterJumpDampingMinSpeedY : float;
                                      human_phys__afterJumpDampingMaxSpeedY : float;
                                      human_phys__afterJumpDampingMinHeight : float;
                                      human_phys__afterJumpDampingMaxHeight : float;
                                      var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  let isInAir = is_in_air(human_phys__inAirTime)
  let wasInAir = was_in_air(human_phys__previousInAirTime, human_phys__inAirTimeThreshold)

  if !wasInAir && isInAir
    currentState.afterJumpDampingHeight = 1.f

  if isInAir && currentState.velocity.y < human_phys__afterJumpDampingMinSpeedY
    currentState.afterJumpDampingHeight = min(
      currentState.afterJumpDampingHeight,
      cvt(currentState.velocity.y, human_phys__afterJumpDampingMinSpeedY, human_phys__afterJumpDampingMaxSpeedY,
                                   human_phys__afterJumpDampingMinHeight, human_phys__afterJumpDampingMaxHeight))


def update_friction(var human_net_phys : HumanActor&; human_phys__crawlTransitionFrictionMult)
  assume currentState = human_net_phys.phys.currentState
  let isGointToCrawl = (int(currentState.states) & int(StateFlag ST_CRAWL)) != 0 && !currentState.isCrawl
  currentState.frictionMult = isGointToCrawl ? human_phys__crawlTransitionFrictionMult : 1.0

[es(tag=netClient, before=human_phys_es, REQUIRE=hero)]
def human_phys_set_crawl_transition_friction_local(info : UpdateStageInfoAct;
                                                   human_phys__crawlTransitionFrictionMult : float;
                                                   var human_net_phys : HumanActor&)
  update_friction(human_net_phys, human_phys__crawlTransitionFrictionMult)

[es(tag=server, before=human_phys_es)]
def human_phys_set_crawl_transition_friction(info : UpdateStageInfoAct;
                                             human_phys__crawlTransitionFrictionMult : float;
                                             var human_net_phys : HumanActor&)
  update_friction(human_net_phys, human_phys__crawlTransitionFrictionMult)

[es]
def reset_delayed_jump_in_transition_to_crawl(update : CmdPostPhysUpdate;
                                              human_phys__crawlThreshold : float;
                                              var human_net_phys : HumanActor)
  assume currentState = human_net_phys.phys.currentState
  if currentState.height < human_phys__crawlThreshold
    currentState.jumpStartTime = -1.
