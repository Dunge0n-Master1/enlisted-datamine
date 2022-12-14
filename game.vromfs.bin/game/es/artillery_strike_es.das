require ecs
require app
require math
require math.base
require DagorMath
require DagorRandom
require Dacoll
require game.es.events


[es(tag=server, REQUIRE=autoShoot, no_order)]
def artillery_strike_update_es(info : UpdateStageInfoAct; auto_shoot__firstShotTime : float; var auto_shoot__shouldShoot : bool&)
  auto_shoot__shouldShoot = info.curTime > auto_shoot__firstShotTime


[es(tag=server, REQUIRE=autoShoot, REQUIRE=auto_shoot__canShoot, track=auto_shoot__canShoot, on_appear)]
def artillery_strike_on_shoot_es(evt : Event;
                                 eid : EntityId;
                                 gun__ammo : int;
                                 gun__maxAmmo : int;
                                 auto_shoot__shotCount : int)
  if gun__maxAmmo - gun__ammo >= auto_shoot__shotCount
    destroyEntity(eid)


[es(tag=server, on_appear)]
def artillery_strike_started_es(evt : Event;
                                eid : EntityId;
                                artillery__callerEid : EntityId;
                                artillery__timeToFirstShot : float;
                                var artillery__nextShotTime : float&)
  let atTime = get_sync_time()
  artillery__nextShotTime = atTime + artillery__timeToFirstShot
  ecs::query(artillery__callerEid) <| $ [es] (artillery__interval : float;
                                              var artillery__availableAtTime : float&;
                                              var artillery__lastShotInTime : float&)
    if atTime > artillery__availableAtTime
      artillery__availableAtTime = atTime + artillery__interval
      artillery__lastShotInTime = atTime
    else
      destroyEntity(eid)


[es(tag=server, no_order)]
def artillery_strike_es(info : UpdateStageInfoAct;
                        eid : EntityId;
                        artillery__gunTempl : string;
                        artillery__autoShootTempl : string;
                        artillery__adjustmentGunTempl : string = "";
                        artillery__callerEid : EntityId;
                        artillery__offender : EntityId;
                        artillery__dispersion : float;
                        var artillery__shotsDone : int&;
                        artillery__shotsCount : int;
                        artillery__adjustmentsShotsCount : int;
                        var artillery__nextShotTime : float&;
                        artillery__timeBetweenShots : float;
                        artillery__timeBetweenAdjustmentsShots : float;
                        artillery__adjustmentDispersion : float;
                        artillery__sourcePos : float3;
                        artillery__targetPos : float3;
                        artillery__targetPosEnd : float3 const?)
  if artillery__shotsDone >= artillery__shotsCount
    destroyEntity(eid)
  if info.curTime < artillery__nextShotTime
    return

  let startPos = artillery__targetPos
  let endPos = artillery__targetPosEnd == null ? artillery__targetPos : *artillery__targetPosEnd

  var gunDispersion : float
  var pos : float3
  var gunTempl = artillery__gunTempl
  if artillery__shotsDone < artillery__adjustmentsShotsCount
    let adjustmentStep = safeinv(float(artillery__adjustmentsShotsCount))
    pos = lerp(startPos, endPos, float3(float(artillery__shotsDone) * adjustmentStep))
    gunDispersion = cvt(float(artillery__shotsDone), 0.0, float(artillery__adjustmentsShotsCount - 1), artillery__adjustmentDispersion, artillery__dispersion)
    gunTempl = artillery__adjustmentGunTempl != "" ? artillery__adjustmentGunTempl : artillery__gunTempl
    artillery__nextShotTime += artillery__timeBetweenAdjustmentsShots
  else
    let step = safeinv(float(artillery__shotsCount - artillery__adjustmentsShotsCount))
    pos = lerp(startPos, endPos, float3(float(artillery__shotsDone) * step))
    gunDispersion = artillery__dispersion
    artillery__nextShotTime += artillery__timeBetweenShots

  let gunTarget = pos + gunDispersion * float3(gsrnd(), 0.0, gsrnd())
  let gunDir = normalize(gunTarget - artillery__sourcePos)
  var tm = IDENT_TM
  tm[3] = artillery__sourcePos
  createEntity("{gunTempl}+{artillery__autoShootTempl}") <| $(var init : ComponentsInitializer)
    set(init, "gun__offender", artillery__offender)
    set(init, "auto_shoot__gunPos", artillery__sourcePos)
    set(init, "auto_shoot__gunDir", gunDir)
    set(init, "auto_shoot__targetPos", gunTarget)
    set(init, "auto_shoot__firstShotTime", info.curTime)
    set(init, "auto_shoot__shotCount", 1)
    set(init, "artillery__callerEid", artillery__callerEid)
    set(init, "transform", tm)

  artillery__shotsDone++
