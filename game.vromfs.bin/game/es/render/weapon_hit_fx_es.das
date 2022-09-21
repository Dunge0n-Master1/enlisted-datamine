require ecs
require ecs.safe
require PhysMat
require DaWeapons
require ecs.common
require debug.logerr_once
require DagorSystem
require Dacoll
require BallisticsProps
require EnlistedWeaponRender
require BloodPuddels
require EnlistedWeapon
require AnimV20
require DagorMath
require CollRes
require math.base
require common_shooter.es.render.blood_common
require common_shooter.events_common_shooter
require weapon_sounds.modules.weapon_sounds_events
require enlisted.events_enlisted
require Dacoll
require BallisticsProps
require strings
require daslib/sort_boost

def private logerr_debug(msg : string)
  if get_DAGOR_DBGLEVEL() > 0
    logerr(msg)

[es(on_appear)]
def global_turret_hit_fx_info_init_es(evt : Event; var global_turret_hit_fx__info : Object&; var global_turret_hit_fx__calibers : FloatList&)
  var calibers : array<float>

  for elem in global_turret_hit_fx__info
    let cal = to_float(elem.key)
    if cal <= 0.0
      logerr("Incorrect value for caliber found in global_turret_hit_fx__info: {elem.key}")
      continue
    push(calibers, cal)

    var entryForCaliber = elem.value as Array
    if entryForCaliber == null
      logerr_once("global_turret_hit_fx__info:object should only have arrays of objects as elements")
      continue

    for elem2 in *entryForCaliber
      var entryForBulletType = elem2 as Object
      if entryForBulletType == null
        logerr_once("global_turret_hit_fx__info:object should only have arrays of objects as elements")
        continue

      let bulletTypeListTmplName = entryForBulletType?.bulletTypeList ?as string
      if bulletTypeListTmplName == null
        logerr_once("Can't find bulletTypeList:t somewhere in global_turret_hit_fx__info")
        continue

      let bulletTypeListTmpl = getTemplateByName(string(*bulletTypeListTmplName))
      if bulletTypeListTmpl == null
        logerr("global_turret_hit_fx__info references non-existent template {bulletTypeListTmplName}")
        continue

      let bulletTypes = get_ecs_StringList(getTemplateComponent(*bulletTypeListTmpl, "bulletTypes"))
      if bulletTypes == null
        logerr("Can't find bulletTypes:list<t> in template {bulletTypeListTmplName}")
        continue

      var bulletTypeHashes = getRW_ecs_UInt32List((*entryForBulletType).bulletTypeHashes)
      if bulletTypeHashes == null
        logerr_once("Can't find bulletTypeHashes:list<u32> somewhere in global_turret_hit_fx__info")
        continue

      for bulletType in *bulletTypes
        push(*bulletTypeHashes, ecs_hash(string(bulletType)))

  sort(calibers)
  for cal in calibers
    push(global_turret_hit_fx__calibers, cal)

def private get_shell_fx_by_mat(gun_eid : EntityId; shell_props_ids : GunShellPropIds; gun_hit_fx__info : Array; shell_id : int16; mat_id : int) : Object const?
  var shellIndex = -1
  for i in iter_range(shell_props_ids)
    if shell_id == shell_props_ids[i].shellId
      shellIndex = i
      break
  if uint(shellIndex) >= uint(length(gun_hit_fx__info))
    logerr_once("Can't find correct shell for gun {getEntityTemplateName(gun_eid)}")
    return null

  let matName = get_material_name(get_material(mat_id))
  let obj = get_ecs_object(gun_hit_fx__info[shellIndex])
  return obj != null ? get_ecs_object(*obj, matName) : null

def private get_turret_hit_fx_by_mat(turret_hit_fx_info_for_bullet_type : Object; mat_id : int) : Object const?
  let matName = get_material_name(get_material(mat_id))
  let infoForMaterials = turret_hit_fx_info_for_bullet_type.info ?as Object
  if infoForMaterials == null
    logerr_once("Can't find 'info:Object' in turret_hit_fx_info_for_bullet_type")
  return infoForMaterials?[matName] ?as Object

def private get_turret_hit_fx_info_for_bullet_type(fx_info : Array; bullet_type_hash : uint)
  for elem in fx_info
    let ret = elem as Object
    if ret == null
      logerr_once("Can't find 'info:object' in fx_info")
      return null

    let bulletTypeHashes = get_ecs_UInt32List(ret?.bulletTypeHashes)
    if bulletTypeHashes == null
      logerr_once("Can't find 'bulletTypeHashes:list<u32>' in an element in fx_info")
      return null

    if has_value(*bulletTypeHashes, bullet_type_hash)
      return ret

  if bullet_type_hash == 0u || bullet_type_hash == ecs_hash("")
    if get_DAGOR_DBGLEVEL() > 0
      logerr_once("Bullet type has not been set for this projectile")
  else
    find_query() <| $ [es] (var global_turret_hit_fx__failedBulletTypeHashes : UInt32List&)
      if !has_value(global_turret_hit_fx__failedBulletTypeHashes, bullet_type_hash)
        logerr_debug("Can't find hit fx info for bullet type with hash {bullet_type_hash}")
        push(global_turret_hit_fx__failedBulletTypeHashes, bullet_type_hash)
      return true
  return null

def private get_global_turret_hit_fx_info_for_caliber_and_bullet_type(caliber : float; bullet_type_hash : uint)
  var ret : Object?

  find_query() <| $ [es] (global_turret_hit_fx__info : Object;
                          global_turret_hit_fx__calibers : FloatList;
                          var global_turret_hit_fx__failedCalibers : FloatList&)
    var closestCal = 0.0
    for cal in global_turret_hit_fx__calibers
      if caliber < cal / 1000.0
        closestCal = cal
        break
    let fxInfosForCaliber = global_turret_hit_fx__info[string(int(closestCal))] ?as Array

    if fxInfosForCaliber == null
      if !has_value(global_turret_hit_fx__failedCalibers, caliber)
        logerr_debug("Can't find information in the singleton global_turret_hit_fx_info for the caliber {caliber} (m)")
        push(global_turret_hit_fx__failedCalibers, caliber)
      return true

    ret = get_turret_hit_fx_info_for_bullet_type(*fxInfosForCaliber, bullet_type_hash)
    return true

  return ret

def private spawn_effect_aux(norm : float3; pos : float3; coll_type : int; fx_name : string)
  var tm : float3x4
  identity(tm)
  tm[1] = normalize(norm)
  tm[2] = normalize(cross(float3(1, 0, 0), tm[1]))
  tm[0] = normalize(cross(tm[1], tm[2]))
  tm[3] = pos

  if (coll_type == int(CollType ETF_LMESH))
    createEntity("hit_fx_readback_info") <| $(init)
      init |> set("transform", tm)
      init |> set("hit_fx_name", fx_name)
  else
    createEntity(fx_name) <| $(init)
      init |> set("transform", tm)

def private spawn_effect(gun_eid : EntityId;
                         launch_desc : LaunchDesc;
                         norm : float3;
                         pos : float3;
                         mat_id : int;
                         coll_type : int;
                         bullet_type_hash : uint;
                         should_stop : bool = true;
                         ricochet_angle : float = 0.0)
  let gunHitFxInfoFound = query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds;
                                                    [[shared_comp]] gun_hit_fx__info : Array;
                                                    gun_hit_fx__default : string)
    let obj = get_shell_fx_by_mat(gun_eid, gun__shell_prop_ids, gun_hit_fx__info, launch_desc.shellId.shellId, mat_id)
    let fxName = obj?.fx ?? gun_hit_fx__default
    spawn_effect_aux(norm, pos, coll_type, fxName)

  if gunHitFxInfoFound
    return true

  var gunIsProperTurret = false
  query(gun_eid) <| $ [es] (isTurret : Tag?; gun__isLauncher : Tag?)
    gunIsProperTurret = (isTurret != null) && (gun__isLauncher == null)

  if !gunIsProperTurret
    return false

  var fxInfo : Object?
  let turretHitFxInfoFound = query(gun_eid) <| $ [es] ([[shared_comp]] turret_hit_fx__info : Array)
    fxInfo = get_turret_hit_fx_info_for_bullet_type(turret_hit_fx__info, bullet_type_hash)

  if !turretHitFxInfoFound
    var caliber : float
    projectile_get_props(int(launch_desc.shellId.shellId)) <| $(ballisticsProps : ProjectileProps)
      caliber = ballisticsProps.caliber
    fxInfo = get_global_turret_hit_fx_info_for_caliber_and_bullet_type(caliber, bullet_type_hash)

  if fxInfo == null
    return false

  let fxByMat = get_turret_hit_fx_by_mat(*fxInfo, mat_id)
  var fxName : das_string const?
  fxName = (ricochet_angle != 0.0 ? fxByMat?.ricochetFx :
            should_stop           ? fxByMat?.fx :
                                    fxByMat?.penetrationFx) ?as string
  if fxName == null
    fxName = (ricochet_angle != 0.0 ? fxInfo?.defaultRicochetFx :
              should_stop           ? fxInfo?.defaultFx :
                                      fxInfo?.defaultPenetrationFx) ?as string
    if fxName == null
      if get_DAGOR_DBGLEVEL() > 0
        logerr_once("Can't find relevant default effect in fxInfo")
      return false

  spawn_effect_aux(norm, pos, coll_type, string(*fxName))
  return true

[es(tag=gameClient, REQUIRE=launch_desc)]
def projectile_hit_scene_es(evt : EventProjectileHitScene; gunEid : EntityId; launch_desc : LaunchDesc; projectile__bulletTypeHash : uint)
  if int(launch_desc.shellId.shellId) < 0
    return
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    if !spawn_effect(gunEid, launch_desc, evt.norm, evt.pos, evt.matId, evt.collType, projectile__bulletTypeHash, evt.shouldStop, evt.ricochetAngle)
      let vel = float3()
      on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), evt.matId, evt.pos, vel, evt.norm)

[es(tag=render)]
def fx_on_shell_explosion_es(evt : CmdShellExplosionFx;
                             eid : EntityId;
                             gunEid : EntityId;
                             scene_hit_place__matId : int;
                             scene_hit_place__pos : float3;
                             scene_hit_place__norm : float3;
                             scene_hit_place__collType : int;
                             projectile_ballistics_props : ProjectileProps;
                             launch_desc : LaunchDesc;
                             projectile__bulletTypeHash : uint)
  if int(launch_desc.shellId.shellId) < 0
    return
  if !spawn_effect(gunEid, launch_desc, scene_hit_place__norm, scene_hit_place__pos, scene_hit_place__matId, scene_hit_place__collType, projectile__bulletTypeHash)
    let vel = float3()
    on_shell_hit_scene_fx(int(launch_desc.shellId.shellId), scene_hit_place__matId, scene_hit_place__pos, vel, scene_hit_place__norm)

  sendEventImmediate(eid, [[CmdPlayProjectileHitSceneSound
    pos=scene_hit_place__pos,
    pmid=scene_hit_place__matId,
    caliber=projectile_ballistics_props.caliber,
    ricochet=0.,
    exploded=true
  ]])

def private spawn_human_binded_fx(fx_tm : float3x4; itm : float3x4; effect_template : string; eid : EntityId; node_coll_id : int; color_mult : E3DCOLOR)
  createEntity(effect_template) <| $(var init)
    init |> set("transform", fx_tm)
    init |> set("effect__colorMult", color_mult)
    init |> set("entity_binded_effect__entity", eid)
    init |> set("entity_binded_effect__collNodeId", node_coll_id)
    init |> set("entity_binded_effect__localEmitter", itm * fx_tm)

def private gen_fx_tm(pos : float3; dir : float3; scale : float)
  var tm = IDENT_TM
  tm[1] = normalize(dir)
  tm[2] = normalize(cross(float3(1, 0, 0), dir))
  tm[0] = normalize(cross(dir, tm[2]))
  for i in range(3)
    tm[i] = tm[i] * scale

  tm[3] = pos
  return tm

def private human_spawn_blood_fx(victim_eid : EntityId; gun_eid : EntityId; launch_desc : LaunchDesc;
                                 mat_id : int; coll_node_id : int; blood_splash : HitBloodType;
                                 pos : float3; dir : float3; scale : float; norm : float3)
  var success = false
  if !is_blood_enabled()
    return true

  query(victim_eid) <| $ [es] (transform : float3x4; animchar : AnimcharBaseComponent; collres : CollisionResource)
    var nodeTm : float3x4
    collres_get_collision_node_tm(collres, coll_node_id, transform, animchar.nodeTree, nodeTm)
    query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds; [[shared_comp]] gun_hit_fx__info : Array)
      let obj = get_shell_fx_by_mat(gun_eid, gun__shell_prop_ids, gun_hit_fx__info, launch_desc.shellId.shellId, mat_id)
      if obj == null
        return

      var fxSection = "fx";
      var fxName = get_string(obj, fxSection, "")
      if blood_splash == HitBloodType TWO_SIDE
        fxSection = "fx_kill"
        fxName = get_string(obj, fxSection, fxName)
      if fxName == ""
        logerr_once("Empty blood fx for gun {getEntityTemplateName(gun_eid)}")
        return

      success = true
      let sideFx = get_string(obj, "{fxSection}_side", "")
      let exitFx = get_string(obj, "{fxSection}_exit", "")
      let bloodColor = get_blood_color()
      let itm = inverse(nodeTm)
      spawn_human_binded_fx(gen_fx_tm(pos, -dir, scale), itm, fxName, victim_eid, coll_node_id, bloodColor);
      let reflectedDir = dir - 2. * dot(norm, dir) * norm
      if sideFx != "" && length_sq(reflectedDir) > 1e-5f
        spawn_human_binded_fx(gen_fx_tm(pos, ((normalize(reflectedDir) + norm) * 0.5f), scale), itm, sideFx, victim_eid, coll_node_id, bloodColor)

      if blood_splash != HitBloodType TWO_SIDE || exitFx == ""
        return
      let t = 2.
      let tracePos = pos + 2. * dir
      let invDir = -dir
      collres_traceray(collres, transform, animchar.nodeTree, tracePos, invDir, t, true) <| $ [unused_argument(_)] (find : bool; isects : CollResIntersectionsType#)
        if find
          let exitNodeId = int(isects[length(isects) - 1].collisionNodeId)
          spawn_human_binded_fx(gen_fx_tm(pos + (2.0f - t) * dir, dir, scale), itm, exitFx, victim_eid, exitNodeId, bloodColor);

  return success

[es(tag=render)]
def on_shell_hit_entity_fx_es(evt : OnShellHitEntityFx; launch_desc : LaunchDesc; gunEid : EntityId; projectile__bulletTypeHash : uint)
  var success = false
  if evt.bloodSplash == HitBloodType NONE
    success = spawn_effect(gunEid, launch_desc, evt.norm, evt.pos, evt.pmid, int(CollType ETF_RI), projectile__bulletTypeHash)
  else
    success = human_spawn_blood_fx(evt.victimEid, gunEid, launch_desc, evt.pmid, evt.nodeCollId, evt.bloodSplash, evt.pos, evt.dir, 1., evt.norm)

  if !success
    on_shell_hit_entity_fx(evt.shellId, evt.pos, evt.dir, evt.pmid, evt.norm, evt.bloodSplash,
      evt.victimEid, evt.nodeCollId, evt.withSound)
    return

  if evt.bloodSplash == HitBloodType TWO_SIDE
    create_blood_puddle_emitter(evt.victimEid, evt.nodeCollId)
  elif evt.bloodSplash == HitBloodType ONE_SIDE
    add_hit_blood_effect(evt.pos, evt.dir)
