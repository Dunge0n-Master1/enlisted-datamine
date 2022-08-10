require ecs
require PhysVars
require math.base
require enlisted.events_enlisted

[es(on_appear, tag=gameClient, REQUIRE=gun__overheat)]
def init_overheat_phys_var(evt : Event;
                           gun__overheatPhysVarName : string;
                           var phys_vars : PhysVars;
                           var gun__overheatVarId : int&)
  gun__overheatVarId = registerVar(phys_vars, gun__overheatPhysVarName, 0.f)

[es(REQUIRE=hero, tag=gameClient)]
def update_overheat_phys_var(info : ParallelUpdateFrameDelayed;
                             human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es] (gun__overheat : float;
                                              gun__overheatVarId : int;
                                              gun__overheadIndicatorMax : float;
                                              var gun__overheatLastVisualVal : float&;
                                              var phys_vars : PhysVars)
    if gun__overheat != gun__overheatLastVisualVal
      gun__overheatLastVisualVal = approach(gun__overheatLastVisualVal, gun__overheat, info.dt, 0.1)
      setVar(phys_vars, gun__overheatVarId, gun__overheatLastVisualVal * gun__overheadIndicatorMax)

