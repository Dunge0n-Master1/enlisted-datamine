require ecs
require game.es.events
require common_shooter.events_common_shooter


[es]
def update_fire_occluder_es(evt : CmdWeapPhysUpdate;
                            var smoke_occluder__sphere : float4&;
                            flamethrower__flameStartOffset : float;
                            flamethrower__cloudStartOffset : float;
                            flamethrower__flameCloudRadius : float;
                            flamethrower__flameCurrentLength : float;
                            flamethrower__fireOccluderRadiusMult : float = 1.5f)
  if !evt.isForReal
    return

  if !evt.gctrl.shoot
    smoke_occluder__sphere[3] = 0.0
    return

  let gloc = evt.gloc
  if gloc.gunPos == null
    return

  let gunPos = *(gloc.gunPos)
  let gunDir = gloc.gunDir

  if (flamethrower__flameCurrentLength > flamethrower__cloudStartOffset)
    let fireCloudLength = max(flamethrower__cloudStartOffset,
                              flamethrower__flameCurrentLength - flamethrower__flameCloudRadius)
    let fireCloudEnd = gunPos + gunDir * (flamethrower__flameStartOffset + fireCloudLength)
    smoke_occluder__sphere = float4(fireCloudEnd[0], fireCloudEnd[1], fireCloudEnd[2],
                                       flamethrower__flameCloudRadius * flamethrower__fireOccluderRadiusMult)
  else
    smoke_occluder__sphere[3] = 0.0