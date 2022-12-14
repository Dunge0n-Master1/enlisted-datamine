require ecs
require math
require math.base
require DaWeapons
require HumanPhys
require DagorRandom
require DagorMath
require EnlistedWeapon
require EnlistedHuman
require EnlistedPhys


def process_aim_offs(var aim_offs : float2&; var aim_angles : float2&; tau, dt : float)
  let delta = approach(aim_offs, float2(0.f), dt, tau) - aim_offs
  aim_offs += delta
  aim_angles -= delta

def private get_compensation_amount(recoil_delta : float; compensate_delta : float)
  if sign(recoil_delta) != sign(recoil_delta + compensate_delta)
    return -recoil_delta

  if abs(recoil_delta) > abs(recoil_delta + compensate_delta)
    return compensate_delta

  return 0.0

[es(tag=input, after=after_guns_update_sync, before=clear_gun_launch_events_es, REQUIRE=watchedByPlr)]
def gun_human_recoil_es(info : UpdateStageInfoAct;
                        var human_net_phys : HumanActor;
                        var human_input__aimOffset : float2&;
                        var human_input__uncompensatedAimOffset : float2&;
                        var human_input__lastShotAt : float&;
                        human_input__decayUncompensatedAimOffsetAfter : float;
                        human_input__decayAimOffsetVisc : float;
                        var human_weap__recoil : float&;
                        var human_weap__curRecoilMult : float&;
                        human_input__oldAimAngle : float2 const?;
                        var human_input__aimAngle : float2?;
                        human_weap__currentGunEid : EntityId;
                        entity_mods__recoilMult = 1.f;
                        human_net_phys__crawlRecoilMult = 0.3f;
                        human_net_phys__crouchRecoilMult = 0.7f;
                        human_net_phys__aimRecoilMult = 0.7f;
                        human_net_phys__recoilOffsMult = 1.f;
                        human_net_phys__recoilControlMult = 0.f;
                        human_input__aimOffsetVisc = 0.1f;
                        entity_mods__verticalRecoilOffsMult = 1.f;
                        entity_mods__horizontalRecoilOffsMult = 1.f;
                        platformRecoilControlMult = 1.f;
                        platformDecayUncompensatedRecoil = false;
                        human_weap__recoilMult = 1.f;
                        bipod__enabled = false;
                        bipod__recoilMult = 1.f;
                        human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
  let currentGunEid  = human_weap__currentGunEid

  if !currentGunEid && !human_attached_gun__attachedGunEid
    return

  let isAttachedGun = !!human_attached_gun__attachedGunEid
  let gunEid = isAttachedGun ? human_attached_gun__attachedGunEid : (get_Eid(currentGunEid, "subsidiaryGunEid") ?? currentGunEid)

  var aimOffsetDelta = float2(0.0, 0.0)

  query(gunEid) <| $ [es] (gun_launch_events : GunLaunchEvents;
                           gun__recoilAmount : float;
                           gun__crawlRecoilMult : float const?;
                           gun__crouchRecoilMult : float const?;
                           gun__aimRecoilMult : float const?;
                           gun__recoilOffsMult : float const?;
                           gun__recoilControlMult : float const?;
                           gun__salt = 0;
                           gun__recoilDirAmount = 0.f;
                           gun__recoilDir = 0.f;
                           gun__visualRecoilMult = 1.f)

    human_weap__curRecoilMult = 1.f

    if human_net_phys.phys.currentState.isCrawl
      human_weap__curRecoilMult = gun__crawlRecoilMult ?? human_net_phys__crawlRecoilMult
    elif human_net_phys.phys.currentState.isCrouch
      human_weap__curRecoilMult = gun__crouchRecoilMult ?? human_net_phys__crouchRecoilMult

    if human_net_phys.phys.currentState.isAiming
      human_weap__curRecoilMult *= gun__aimRecoilMult ?? human_net_phys__aimRecoilMult

    if bipod__enabled
      human_weap__curRecoilMult *= bipod__recoilMult

    human_weap__curRecoilMult *= entity_mods__recoilMult * human_weap__recoilMult

    if length(gun_launch_events.launchEvents) == 0
      return

    for event in gun_launch_events.launchEvents
      var seed = phys_time_to_seed(event.atTime) ^ gun__salt
      let ang = _frnd(seed) * TWOPI
      let omniOffs = float2(sin(ang), cos(ang))
      let dirOffs = float2(sin(gun__recoilDir), cos(gun__recoilDir))
      var offs = lerp(omniOffs, dirOffs, float2(gun__recoilDirAmount)) * gun__recoilAmount * human_weap__curRecoilMult
      offs.x *= entity_mods__horizontalRecoilOffsMult
      offs.y *= entity_mods__verticalRecoilOffsMult
      human_net_phys.phys.currentState.gunAimOffset += offs * (gun__recoilOffsMult ?? human_net_phys__recoilOffsMult)
      aimOffsetDelta += offs * (gun__recoilControlMult ?? human_net_phys__recoilControlMult) * platformRecoilControlMult
      human_weap__recoil += gun__recoilAmount * human_weap__curRecoilMult * gun__visualRecoilMult

    human_input__aimOffset += aimOffsetDelta

    human_input__uncompensatedAimOffset -= aimOffsetDelta
    human_input__lastShotAt = info.curTime

  if human_input__aimAngle != null && human_input__oldAimAngle != null
    // its important to calculate this delta before changing human_input__aimAngle due to recoil
    // otherwise we wont be able to tell if the user tried to comepnsate the recoil or it was another shot
    // that changed that delta
    let aimAngleDelta = *human_input__oldAimAngle - *human_input__aimAngle
    let aimAngleDeltaNorm = float2(norm_s_ang(aimAngleDelta.x), norm_s_ang(aimAngleDelta.y))

    let compensationAmount = float2(get_compensation_amount(human_input__uncompensatedAimOffset.x, aimAngleDeltaNorm.x),
                                    get_compensation_amount(human_input__uncompensatedAimOffset.y, aimAngleDeltaNorm.y))

    human_input__uncompensatedAimOffset += compensationAmount


    if !platformDecayUncompensatedRecoil || info.curTime < human_input__lastShotAt + human_input__decayUncompensatedAimOffsetAfter
      process_aim_offs(human_input__aimOffset, *human_input__aimAngle, human_input__aimOffsetVisc, info.dt)
    else
      process_aim_offs(human_input__uncompensatedAimOffset, *human_input__aimAngle, human_input__decayAimOffsetVisc, info.dt)
  else
    human_input__aimOffset = float2(0.f)
