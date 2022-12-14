require ecs
require app
require game.utils.team
require game.utils.hero
require game.es.render.render_events
require common_shooter.es.human_weap_common
require dm
require DagorSystem
require DagorMath
require CollRes
require RendInst
require HumanPhys
require EnlistedHuman
require EnlistedWeapon
require EnlistedUI
require Gun


def check_crosshair_hintable_objects(var tracePos : float3&;
                                     var traceDir : float3&;
                                     traceLen : float;
                                     ownTeam : int)
  let eps = 0.05
  var needHint = false
  find_query() <| $ [es(REQUIRE=hasCrosshairHint)] (transform : float3x4;
                                                    collres : CollisionResource;
                                                    team : int)
    if collres |> collres_rayhit(transform, null, tracePos, traceDir, traceLen + eps)
      needHint = is_teams_friendly(team, ownTeam)
    return needHint ? true : false

  if needHint
    return needHint

  find_query() <| $ [es(REQUIRE=hasCrosshairHint)] (transform : float3x4;
                                                    ri_extra : RiExtraComponent;
                                                    team : int = TEAM_UNASSIGNED;
                                                    destroyable_ri__addScoreTeam : int = TEAM_UNASSIGNED)

    let riType = int(handle_to_ri_type(ri_extra.handle))
    let collRes = get_rigen_extra_coll_res(riType)
    if collRes != null && *collRes |> collres_rayhit(transform, null, tracePos, traceDir, traceLen + eps)
      if destroyable_ri__addScoreTeam == TEAM_UNASSIGNED
        needHint = is_teams_friendly(team, ownTeam)
      else
        needHint = !is_teams_friendly(destroyable_ri__addScoreTeam, ownTeam)
    return needHint ? true : false
  return needHint


[es(before=ui_render_es, after=human_weap_update_es)]
def ui_crosshair_state_es(info : RenderEventUI;
                          ui_crosshair_state__defaultColor : E3DCOLOR;
                          ui_crosshair_state__notPenetratedColor : E3DCOLOR;
                          ui_crosshair_state__ineffectiveColor : E3DCOLOR;
                          ui_crosshair_state__effectiveColor : E3DCOLOR;
                          ui_crosshair_state__possibleEffectiveColor : E3DCOLOR;
                          ui_crosshair_state__allowShooting : bool;
                          var ui_crosshair_state__reloadEndTime : float&;
                          var ui_crosshair_state__reloadTotalTime : float&;
                          var ui_crosshair_state__canShoot : bool&;
                          var ui_crosshair_state__teammateAim : bool&;
                          var ui_crosshair_state__isAimPressed : bool&;
                          var ui_crosshair_state__isAiming : bool&;
                          var ui_crosshair_state__overheat : float&;
                          var ui_crosshair_state__deviation : float2&;
                          var ui_crosshair_state__aimPos : float3&;
                          var ui_crosshair_state__color : E3DCOLOR&)
  var spread = float2()

  ui_crosshair_state__aimPos = float3()
  ui_crosshair_state__deviation = float2()

  ui_crosshair_state__isAimPressed = false
  ui_crosshair_state__isAiming = false
  ui_crosshair_state__overheat = 0.0
  ui_crosshair_state__reloadEndTime = 0.0
  ui_crosshair_state__reloadTotalTime = 0.0
  ui_crosshair_state__teammateAim = false
  ui_crosshair_state__canShoot = false

  let hero = get_controlled_hero()

  var isInVehicle = false
  var mortarMode = false
  var attachedGunEid = INVALID_ENTITY_ID
  var ownTeam = TEAM_UNASSIGNED
  var intersectionEid = INVALID_ENTITY_ID
  var gunTraceLen = 0.0
  var human : HumanActor const? = null
  query(hero) <| $ [es] (isInVehicle aka hero_isInVehicle : bool = false;
                         human_weap__mortarMode : bool = false;
                         human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                         team : int = TEAM_UNASSIGNED;
                         human_weap__traceIntersectedEid : EntityId = INVALID_ENTITY_ID;
                         human_weap__tracerayLen : float = 0.0;
                         human_net_phys : HumanActor const?)
    isInVehicle = hero_isInVehicle
    mortarMode = human_weap__mortarMode
    attachedGunEid = human_attached_gun__attachedGunEid
    ownTeam = team
    intersectionEid = human_weap__traceIntersectedEid
    gunTraceLen = human_weap__tracerayLen
    human = human_net_phys

  assume phys = human.phys
  ui_crosshair_state__isAimPressed = human != null && phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM)

  if isInVehicle && !ui_crosshair_state__isAimPressed
    return

  if mortarMode
    return

  let curTime = get_sync_time()

  let gunEid = get_human_gun_eid(hero)

  ui_crosshair_state__isAiming = (human != null && phys.currentState.isAiming)

  if ui_crosshair_state__allowShooting && is_human_allowed_shooting(hero)
    query(gunEid) <| $ [es] (gun : Gun; gun__timeBetweenShotsIsReload : Tag const?; gun__overheat : float = 0.0)
      ui_crosshair_state__canShoot = true
      spread = gun |> lerpSpread(curTime)
      ui_crosshair_state__overheat = gun__overheat
      if gunEid == attachedGunEid && gun__timeBetweenShotsIsReload != null && curTime < gun.nextShotAtTime
        ui_crosshair_state__reloadEndTime = gun.nextShotAtTime
        ui_crosshair_state__reloadTotalTime = gun.timeBetweenShots

  var uiViewItm : float3x4
  get_ui_view_itm(uiViewItm)
  var uiViewTm : float3x4
  get_ui_view_tm(uiViewTm)

  if ui_crosshair_state__canShoot
    var shootTm : float3x4
    var tracePos : float3
    var traceDir : float3

    if human_weap_get_aim_tm(hero, curTime, shootTm)
      traceDir = shootTm[0]
      tracePos = shootTm[3]
    else
      tracePos = uiViewItm[3]
      traceDir = uiViewItm[2]
      ui_crosshair_state__canShoot = false

    if intersectionEid != INVALID_ENTITY_ID
      let isAllowFriendlyDamage = has(intersectionEid, "allow_friendly_damage")
      let intersectionTeam = get_int(intersectionEid, "team") ?? TEAM_UNASSIGNED
      let isTeamsFriendly = is_teams_friendly(intersectionTeam, ownTeam)
      let isIntersectionAlive = get_bool(intersectionEid, "isAlive") ?? false
      ui_crosshair_state__teammateAim = !isAllowFriendlyDamage && isTeamsFriendly && isIntersectionAlive

    if check_crosshair_hintable_objects(tracePos, traceDir, gunTraceLen, ownTeam)
      ui_crosshair_state__teammateAim = true
    if ui_crosshair_state__canShoot
      let targetPos = tracePos + traceDir * gunTraceLen
      ui_crosshair_state__aimPos = uiViewTm * targetPos

  ui_crosshair_state__canShoot = ui_crosshair_state__canShoot && ui_crosshair_state__aimPos.z > 1e-4

  ui_crosshair_state__deviation.x = 0.5 * tan(spread.x)
  ui_crosshair_state__deviation.y = 0.5 * tan(spread.y)

  ui_crosshair_state__color = ui_crosshair_state__defaultColor

  query(gunEid) <| $ [es] (gunCheckHitResult : int)
    let hitCheckResult = (gunCheckHitResult < 0 ? int(TestResult INEFFECTIVE)
                                                : gunCheckHitResult)

    if (hitCheckResult == int(TestResult NOT_PENETRATE) ||
        hitCheckResult == int(TestResult RICOCHET))
      ui_crosshair_state__color = ui_crosshair_state__notPenetratedColor
    elif hitCheckResult == int(TestResult INEFFECTIVE)
      ui_crosshair_state__color = ui_crosshair_state__ineffectiveColor
    elif hitCheckResult == int(TestResult EFFECTIVE)
      ui_crosshair_state__color = ui_crosshair_state__effectiveColor
    elif hitCheckResult == int(TestResult POSSIBLE_EFFECTIVE)
      ui_crosshair_state__color = ui_crosshair_state__possibleEffectiveColor