require ecs
require DagorMath
require common_shooter.events_common_shooter

[es(tag=(server, net), REQUIRE_NOT=playerIsBot, on_appear, track=(scoring_player__killsByPlayer, newbie__baseKillCount, newbie__killCountMax))]
def newbie_update_damage_on_kill(evt : Event;
                                 scoring_player__killsByPlayer : int;
                                 newbie__killCountMax : int;
                                 newbie__damageFromBots : float;
                                 newbie__damageToBots : float;
                                 newbie__baseKillCount : int;
                                 var player__damageFromBotsScale : float&;
                                 var player__damageToBotsScale : float&)
  if newbie__killCountMax <= newbie__baseKillCount
    return
  let killCount = float(newbie__baseKillCount + scoring_player__killsByPlayer)
  let killCountMax = float(newbie__killCountMax)
  player__damageFromBotsScale = cvt(killCount, 0., killCountMax, newbie__damageFromBots, 1.0)
  player__damageToBotsScale = cvt(killCount, 0., killCountMax, newbie__damageToBots, 1.0)
