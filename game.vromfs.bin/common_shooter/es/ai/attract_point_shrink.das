require ecs

[es(tag=server, no_order)]
def shrink_attract_point(act : UpdateStageInfoAct; attract_point__shrinkSpeed : float;
                         attract_point__minMagnitude = 1f; var attract_point__magnitude : float&)
  attract_point__magnitude = max(attract_point__minMagnitude, attract_point__magnitude - attract_point__shrinkSpeed * act.dt)
