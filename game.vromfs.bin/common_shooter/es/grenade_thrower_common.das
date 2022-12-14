module grenade_thrower_common shared
require ecs
require app
require game.es.events
require game.utils.animchar
require game.utils.team
require math.base
require common_shooter.events_common_shooter
require EnlistedWeapon
require EnlistedPhys
require EnlistedNet
require EnlistedWeapon
require DaWeapons
require DaWeaponProps
require DagorSystem
require Gun
require HumanPhys
require AnimV20
require common_shooter.es.human.human_gun_common

def attach_projectile(owner_eid : EntityId;
                      gun_eid : EntityId;
                      projectile_entity : EntityId;
                      attach : bool;
                      have_ammo : bool)
  var result = false
  query(projectile_entity) <| $ [es] (gun_attach__mainSlotId : int;
                                      gun_attach__holsterSlotsIds : IntList const?;
                                      var slot_attach__slotId : int&;
                                      var gun__visible : bool&)
    if attach
      anim_attach(slot_attach__slotId, owner_eid, gun_attach__mainSlotId, projectile_entity)
    elif have_ammo && gun_attach__holsterSlotsIds != null && (*gun_attach__holsterSlotsIds)[int(HUWeaponSlots EWS_GRENADE)] >= 0
      anim_attach(slot_attach__slotId, owner_eid, (*gun_attach__holsterSlotsIds)[int(HUWeaponSlots EWS_GRENADE)], projectile_entity)
    else
      anim_detach(slot_attach__slotId, projectile_entity)

    gun__visible = attach && get_bool(owner_eid, "human_weap__throwMode") ?? false
    if attach && gun_eid != INVALID_ENTITY_ID
      set(gun_eid, "human_gun_attached", true)
    result = true
  return result


def obtain_grenade_thrower_projectile_entity(var grenade_thrower__projectileEntity : EntityId&)
  if !doesEntityExist(grenade_thrower__projectileEntity)
    return INVALID_ENTITY_ID
  attach_projectile(INVALID_ENTITY_ID, INVALID_ENTITY_ID, grenade_thrower__projectileEntity, false, false)
  let ent = grenade_thrower__projectileEntity
  grenade_thrower__projectileEntity = INVALID_ENTITY_ID
  return ent


def throw_grenade_away(eid : EntityId;
                       grenade_eid : EntityId;
                       human_weap__gunEids : EidList)
  var res = false
  query(grenade_eid) <| $ [es] (shell__hudMarkerTemplate : string = "";
                                shell__shell_id__shell_id : int;
                                shell__shell_id__damage_id : int;
                                shell__shell_id__ballistics_id : int;
                                shell__gun_props_id : int;
                                shell__explTime : float;
                                transform : float3x4;
                                shell__owner : EntityId = INVALID_ENTITY_ID;
                                shell__rethrower : EntityId = INVALID_ENTITY_ID;
                                var active : bool&;
                                var gun__visible : bool?)
    shell_entity_get_props(shell__shell_id__shell_id) <| $(entProps : ShellEntityTypeProps)
      let templName = entProps.templName
      if templName == ""
        return
      res = true
      using() <| $(var new_shell_props : ShellPropIds#)
        new_shell_props.shellId = int16(shell__shell_id__shell_id)
        new_shell_props.damageId = int16(shell__shell_id__damage_id)
        new_shell_props.ballisticsId = int16(shell__shell_id__ballistics_id)

        let gunEid = human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]
        query(gunEid) <| $ [es] (var shell_props : ShellPropIds;
                                 var gun__ammo : int&;
                                 var gun__curShellId : ShellPropIds;
                                 var gun : Gun;
                                 var human_gun_attached : bool&;
                                 var grenade_thrower__projectileEntity : EntityId&)
          // shell__owner is always someone, who throwed the grenade first, or rethrowed an unowned grenade
          // If the grenade already has a rethrower, it's (for simplicity) overwritten, which is a very rare case anyway

          var newShellOwner = shell__owner
          var newShellRethrower = shell__rethrower

          if shell__owner == INVALID_ENTITY_ID
            newShellOwner = eid
          else
            // rethrower is remembered, so he will be rewarded if the rethrow is "successfull" (kills rethrower's foes)
            // also we need to remember him do a proper cleanup in case the grenade explodes in his hand
            newShellRethrower = eid

          human_gun_attached = false
          shell_props := new_shell_props
          gun__ammo = gun__ammo + 1
          gun__curShellId := new_shell_props

          gun.curState.loaded = (gun__ammo != 0)

          if is_server()
            destroyEntity(grenade_eid)
            destroyEntity(grenade_thrower__projectileEntity)
            grenade_thrower__projectileEntity = INVALID_ENTITY_ID
          else
            if gun__visible != null
              *gun__visible = false
            active = false

          var templateName = ""
          if shell__hudMarkerTemplate != ""
            templateName = add_sub_template_name(templName, shell__hudMarkerTemplate)
          else
            templateName = templName

          let startVel = float3()
          // "transform" for a grenade in hand used as a fallback, if the grenade explodes before it gets attached to the player hand
          // it's possible if either grenade explosion or player death occurs in few frames after the rethrow is initiated
          grenade_thrower__projectileEntity = create_shell_entity(templateName, transform, startVel,
                                                                  newShellOwner, new_shell_props,
                                                                  shell__gun_props_id, /*launch_time*/ get_sync_time(),
                                                                  shell__explTime, /*in_active*/ true, /*clientSide*/ !is_server(),
                                                                  newShellRethrower)

          if !is_server()
            query(eid) <| $ [es] (var human_weap__localProjectileEid : EntityId&)
              destroyEntity(human_weap__localProjectileEid)
              human_weap__localProjectileEid = grenade_thrower__projectileEntity
  return res

def find_rethrowable_grenade(to_whom : EntityId)
  var res = INVALID_ENTITY_ID
  query(to_whom) <| $ [es] (transform aka human_transform : float3x4; human_use_object__rethrowDist : float = 2.5f)
    let humanPos = human_transform[3]
    let humanDir = human_transform[0].xz
    query() <| $ [es(REQUIRE_NOT=shell__blockRethrow)] (eid : EntityId;
                                                        active : bool;
                                                        transform : float3x4;
                                                        slot_attach__attachedTo : EntityId;
                                                        shell__explTime : float;
                                                        shell__shell_id__shell_id : int;
                                                        shell__rethrowTime : float = 4.0f)
      if slot_attach__attachedTo != INVALID_ENTITY_ID || !active
        return

      var adjustedRethrowTime = shell__rethrowTime
      // In online game server allows to rethrow a grenade for a little more time
      // So if the controls packet arrives a bit late (due to net lag), rethrow still happens
      // This fixes the situation, when the client rethrows the grenade close to the end of rethrowTime
      if is_true_net_server()
        adjustedRethrowTime += PHYS_MAX_CONTROLS_TICKS_DELTA_SEC

      var timer = 0.0f
      detonation_get_props(shell__shell_id__shell_id) <| $(detonationProps : DetonationProps)
        timer = detonationProps.timer

      let restTime = timer - min(adjustedRethrowTime, timer)
      if get_sync_time() > shell__explTime - restTime
        return

      let shellPos = transform[3]
      if length_sq(humanPos - shellPos) > square(human_use_object__rethrowDist)
        return

      if dot(humanDir, shellPos.xz - humanPos.xz) > 0.0
        res = eid
  return res
