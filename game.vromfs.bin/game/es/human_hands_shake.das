require ecs
require EnlistedHuman
require DagorMath
require enlisted.events_enlisted

def hands_shake_fade_impl(cur_time : float;
                          concussion__isActive : bool;
                          concussion__endTime : float;
                          concussion__handsShakeFadeTime : float;
                          concussion__handsShakeSpeedMult : float;
                          concussion__handsShakeMagnitude : float;
                          hands_shake__speedMult : float;
                          hands_shake__magnitude : float;
                          var human_net_phys : HumanActor)
  if !concussion__isActive
    human_net_phys.phys.currentState.handsShakeSpeedMult = hands_shake__speedMult
    human_net_phys.phys.currentState.handsShakeMagnitude = hands_shake__magnitude
    return
  let fadeMult = cvt(cur_time, concussion__endTime - concussion__handsShakeFadeTime, concussion__endTime, 1.0, 0.0)
  human_net_phys.phys.currentState.handsShakeSpeedMult = max(hands_shake__speedMult, concussion__handsShakeSpeedMult)
  human_net_phys.phys.currentState.handsShakeMagnitude = max(hands_shake__magnitude, concussion__handsShakeMagnitude * fadeMult)

[es(tag=netClient, REQUIRE=watchedByPlr, no_order)]
def hands_shake_client(info : ParallelUpdateFrameDelayed;
                       concussion__isActive : bool;
                       concussion__endTime : float;
                       concussion__handsShakeFadeTime : float;
                       concussion__handsShakeSpeedMult : float;
                       concussion__handsShakeMagnitude : float;
                       hands_shake__speedMult : float = 1.0;
                       hands_shake__magnitude : float = 0.0;
                       var human_net_phys : HumanActor)
  hands_shake_fade_impl(info.curTime, concussion__isActive, concussion__endTime, concussion__handsShakeFadeTime,
                        concussion__handsShakeSpeedMult, concussion__handsShakeMagnitude,
                        hands_shake__speedMult, hands_shake__magnitude, human_net_phys)

[es(tag=server, no_order)]
def hands_shake_server(info : ParallelUpdateFrameDelayed;
                       concussion__isActive : bool;
                       concussion__endTime : float;
                       concussion__handsShakeFadeTime : float;
                       concussion__handsShakeSpeedMult : float;
                       concussion__handsShakeMagnitude : float;
                       hands_shake__speedMult : float = 1.0;
                       hands_shake__magnitude : float = 0.0;
                       var human_net_phys : HumanActor)
  hands_shake_fade_impl(info.curTime, concussion__isActive, concussion__endTime, concussion__handsShakeFadeTime,
                        concussion__handsShakeSpeedMult, concussion__handsShakeMagnitude,
                        hands_shake__speedMult, hands_shake__magnitude, human_net_phys)

[es(tag=server, track=burning__isBurning, on_appear)]
def burning_hands_shake(evt : Event;
                        burning__isBurning : bool;
                        burning__handsShakeSpeedMult : float;
                        burning__handsShakeMagnitude : float;
                        var hands_shake__speedMult : float&;
                        var hands_shake__magnitude : float&)
  if burning__isBurning
    hands_shake__speedMult = burning__handsShakeSpeedMult
    hands_shake__magnitude = burning__handsShakeMagnitude
  else
    hands_shake__speedMult = 1.
    hands_shake__magnitude = 0.
