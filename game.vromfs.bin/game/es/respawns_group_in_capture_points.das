require ecs
require game.utils.team

def set_respawns_group_on_point_active(group, respawnTeam)
  ecs::query() <| $ [es] (var active : bool&; respawnBaseGroup : int; team : int)
    if respawnBaseGroup == group
      active = team == respawnTeam

[es(tag=server, track=capzone__progress, track=capzone__capTeam, track=active)]
def activate_respawn_on_point_es(evt : Event;
                                 active : bool;
                                 capzone__capTeam : int;
                                 capzone__progress : float;
                                 capzone__activateRespawnOnProgress : float;
                                 capzone__acivateRespawnGroup : int)
  let enoughProgress = capzone__progress >= capzone__activateRespawnOnProgress
  let respawnForTeam = (active && enoughProgress) ? capzone__capTeam : TEAM_UNASSIGNED
  set_respawns_group_on_point_active(capzone__acivateRespawnGroup, respawnForTeam)