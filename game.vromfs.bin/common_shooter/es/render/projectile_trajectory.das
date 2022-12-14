require ecs
require DaWeaponProps
require EnlistedHuman
require EnlistedWeapon
require GamePhys
require Gun
require HumanPhys
require math

[es(tag=render, after=(net_phys_update_es, grenade_thrower_detach_es, grenade_thrower_es))]
def projectile_trajectory(act : UpdateStageInfoAct;
                          calcProjectileTrajectory : bool;
                          human_weap__gunEids : EidList;
                          human_net_phys : HumanActor;
                          human_weap__throwMode : bool;
                          isAlive : bool;
                          var trajectory__enabled : bool&;
                          var trajectory__start : float3&;
                          var trajectory__vel : float3&;
                          isDowned = false)
  if !calcProjectileTrajectory
    return
  trajectory__enabled = human_weap__throwMode && isAlive && !isDowned
  if !trajectory__enabled
    return

  let gunEid : EntityId = human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]
  query(gunEid) <| $ [es] (gun : Gun const?; grenade_thrower : GrenadeThrower const?)
    if gun == null || (grenade_thrower != null && int((*grenade_thrower).state) < int(GrenadeThrowState GTS_DRAW))
      trajectory__enabled = false
  if !trajectory__enabled
    return

  trajectory__enabled = false
  query(gunEid) <| $ [es] (gun__curShellId : ShellPropIds)
    if int(gun__curShellId.shellId) >= 0
      trajectory__enabled = true
      // Projectile is always launched from the first-person view, so the launch point is a server-client consistent
      assume curState = human_net_phys.phys.currentState
      var locationTm : float3x4
      location_toTM(human_net_phys.phys.visualLocation, locationTm)
      var shootTm : float3x4
      human_phys_calcGunTm(human_net_phys.phys,
                          PrecomputedPresetMode FPV,
                          locationTm,
                          curState.gunAngles.y,
                          curState.leanPosition,
                          curState.height,
                          shootTm)

      shell_start_get_props(int(gun__curShellId.shellId)) <| $(shellStartProps : ShellStartProps)
        trajectory__start = shootTm[3]
        var pitch = shellStartProps.pitch
        let gunPitch = asin(shootTm[0].y)
        pitch = gunPitch + pitch > PI / 2. ? PI / 2. - gunPitch : pitch
        let deltaVer = sin(pitch)
        shootTm[3] = float3(0, 0, 0)
        trajectory__vel = (shootTm * float3(sqrt(1.f - deltaVer * deltaVer), deltaVer, 0.f)) * shellStartProps.speed
