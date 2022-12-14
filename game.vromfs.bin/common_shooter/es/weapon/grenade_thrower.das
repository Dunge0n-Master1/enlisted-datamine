require ecs
require ecs.common
require game.es.events
require game.utils.animchar
require common_shooter.events_common_shooter
require common_shooter.es.grenade_thrower_common
require EnlistedWeapon
require EnlistedPhys
require DaWeapons
require DaWeaponProps
require Gun
require HumanPhys
require AnimV20
require DagorSystem


def is_in_range(val : float; min : float; max : float)
  return val > min && val <= max


[es]
def grenade_thrower_phys_es(evt : CmdWeapPhysUpdate;
                            eid : EntityId;
                            gun__curShellId : ShellPropIds;
                            human_gun_attached : bool;
                            grenade_throw__drawTime : float;
                            grenade_throw__throwTime : float;
                            grenade_throw__cookProgressTime : float;
                            grenade_throw__throwProgressTime : float;
                            grenade_throw__fastThrowCookProgressTime : float;
                            grenade_throw__fastThrowProgressTime : float;
                            grenade_thrower__projectileEntity : EntityId = INVALID_ENTITY_ID;
                            var grenade_thrower : GrenadeThrower)
  let isForReal = evt.isForReal
  if !isForReal
    return

  let ownerEid = evt.owner
  let atTime = evt.atTime
  let dt = evt.dt
  var gctrl = evt.gctrl
  assume gloc = evt.gloc

  query(ownerEid) <| $ [es] (isInVehicle : bool = false;
                             human_vehicle__isHoldingGunPassenger : bool = false;
                             human_weap__fastThrowExclusive : bool = true;
                             human_inventory__entityUseEnd : float = -1.0)
    if !human_gun_attached && (!isInVehicle || human_vehicle__isHoldingGunPassenger) && evt.atTime > human_inventory__entityUseEnd
      sendEvent(eid, [[CmdWeapAttach toEid=ownerEid, isAttached=true, slotId=int(HUWeaponSlots EWS_GRENADE)]])

    // TODO: reformat to simple FSM, so it'll be easier to read/understand
    if grenade_thrower.state == GrenadeThrowState GTS_READY
      verify(grenade_thrower.throwProgress == 0.0)
      if gctrl.shoot
        // Start fetching the grenade
        grenade_thrower.state = GrenadeThrowState GTS_DRAW
        grenade_thrower.stateStart = atTime
        grenade_thrower.stateEnd = atTime + grenade_throw__drawTime
        sendEvent(ownerEid, [[EventOnGrenadeThrow gun_props_id=int(gun__curShellId.shellId)]])
      // else
      //   Doing nothing
      //   Progress stays at 0
    elif grenade_thrower.state == GrenadeThrowState GTS_DRAW
      if atTime > grenade_thrower.stateEnd
        // grenade_thrower.throwProgress isn't guaranteed to reach exactly 0.5
        // arTime + dt on frame N can be less, than atTime on frame N + 1
        verify(grenade_thrower.throwProgress <= 0.5)
        if !gctrl.shoot // Trigger is released
          // Starting to throw the grenade
          grenade_thrower.state = GrenadeThrowState GTS_THROW
          grenade_thrower.stateStart = atTime
          grenade_thrower.stateEnd = atTime + grenade_throw__throwTime
        // else
        //   Waiting with the grenade in hand
        //   grenade_thrower.progress stays at 0.5
      else
        // Draw in progress
        // grenade_thrower.progress goes from 0 to 0.5
        // grenade_thrower.progress can be exactly 0 at this point only if app.timeSpeed == 0
        verify(grenade_thrower.throwProgress >= 0.0 && grenade_thrower.throwProgress <= 0.5)
    elif grenade_thrower.state == GrenadeThrowState GTS_THROW
      if atTime > grenade_thrower.stateEnd
        // Throw is finished
        // grenade_thrower.throwProgress isn't guaranteed to reach exactly 1.0 because of floating point errors
        verify(grenade_thrower.throwProgress <= 1.0)
        grenade_thrower.state = GrenadeThrowState GTS_READY
      else
        // Throw in progress
        // grenade_thrower.progress goes from 0.5 to 1.0
        // grenade_thrower.progress can be exactly 0.5 at this point only if app.timeSpeed == 0
        verify(grenade_thrower.throwProgress >= 0.5 && grenade_thrower.throwProgress <= 1.0)

    let prevThrowProgress = grenade_thrower.throwProgress
    grenade_thrower.throwProgress = calc_grenade_throw_progress(grenade_thrower, atTime + dt)

    if grenade_thrower__projectileEntity != INVALID_ENTITY_ID
      let cookProgressTime = human_weap__fastThrowExclusive ? grenade_throw__fastThrowCookProgressTime : grenade_throw__cookProgressTime
      if is_in_range(cookProgressTime, prevThrowProgress, grenade_thrower.throwProgress)
        // activating client-side grenade too, so it have correct explTime
        query(grenade_thrower__projectileEntity) <| $ [es] (shell__shell_id__shell_id : int;
                                                            var shell__explTime : float&;
                                                            var active : bool&)
          if active
            return
          detonation_get_props(shell__shell_id__shell_id) <| $(detonationProps : DetonationProps)
            shell__explTime = atTime + detonationProps.timer
            active = true

    if !human_gun_attached
      return

    // if throwProgressTime is set < 0.5, the grenade won't be thrown because the GTS_DRAW stage isn't finished
    let throwProgressTime = human_weap__fastThrowExclusive ? grenade_throw__fastThrowProgressTime : grenade_throw__throwProgressTime
    gctrl.shoot = (grenade_thrower.state == GrenadeThrowState GTS_THROW &&
                  is_in_range(throwProgressTime,
                              prevThrowProgress,
                              grenade_thrower.throwProgress))

    let rndSeed = phys_time_to_seed(atTime)
    sendEventImmediate(eid, [[CmdGunUpdate atTime=atTime, isForReal=isForReal, seed=rndSeed, gctrl=gctrl, gloc=gloc]])


[es(on_appear)]
def grenade_thrower_shoot_node_init(evt : Event;
                                    grenade_thrower__shootNode : string;
                                    var grenade_thrower__shootNodeId : int&)
  grenade_thrower__shootNodeId = animchar_getSlotId(grenade_thrower__shootNode)
  if grenade_thrower__shootNodeId < 0
    logerr("Failed to get node {grenade_thrower__shootNode} for grenade_thrower")


[es(before=human_gun_attach_es)]
def grenade_thrower_attach_es(evt : CmdWeapAttach;
                              eid : EntityId;
                              grenade_thrower__projectileEntity : EntityId;
                              gun__ammo : int;
                              grenade_thrower__shootNodeId : int;
                              var gun : Gun;
                              var human_gun_attached : bool&;
                              var grenade_thrower__selectedGrenadeVarId : int&)
  let wasHumanGunAttached = human_gun_attached
  let ownerEid = evt.toEid
  let attachFlag = evt.isAttached
  if !attach_projectile(ownerEid, eid, grenade_thrower__projectileEntity, attachFlag, gun__ammo > 0)
    return

  query(grenade_thrower__projectileEntity) <| $ [es] (grenade__selectedWeaponVar : string)
    grenade_thrower__selectedGrenadeVarId = animV20_add_enum_value(grenade__selectedWeaponVar)


  if !wasHumanGunAttached
    query(ownerEid) <| $ [es] (animchar : AnimcharBaseComponent)
      let geomNodeTree = animchar.nodeTree
      if geomNodeTree != null && grenade_thrower__shootNodeId >= 0
        gun |> gun_loadShootNode(grenade_thrower__shootNodeId, *geomNodeTree)

  if !attachFlag
    human_gun_attached = false


[es]
def grenade_thrower_detach_es(evt : CmdWeapDetach;
                              grenade_thrower__projectileEntity : EntityId)
  if grenade_thrower__projectileEntity != INVALID_ENTITY_ID
    sendEvent(grenade_thrower__projectileEntity, [[CmdWeapDetach]])

[es(tag=server, on_disappear, after=human_weap_drop_grenade_es)]  // in the drop_grenade ES the active flag is possibly set to true
def grenade_thrower_destroy_projectile_es(evt : Event;
                                          var grenade_thrower__projectileEntity : EntityId&)
  query(grenade_thrower__projectileEntity) <| $ [es] (active : bool)
    if !active
      destroyEntity(grenade_thrower__projectileEntity)
      grenade_thrower__projectileEntity = INVALID_ENTITY_ID

[es(tag=server, on_disappear, REQUIRE=shell__explTime)]
def grenade_thrower_on_destroy_es(evt : Event;
                                  eid : EntityId)
  find_query() <| $ [es] (var grenade_thrower__projectileEntity : EntityId&)
    if grenade_thrower__projectileEntity != eid
      return false
    grenade_thrower__projectileEntity = INVALID_ENTITY_ID
    return true


[es(tag=server, track=(gun__totalAmmo, gun__wishAmmoItemType), REQUIRE=grenade_thrower)]
def mark_slot_on_grenades(evt : Event;
                          eid, gun__owner : EntityId;
                          gun__totalAmmo, gun__wishAmmoItemType : int)
  if gun__totalAmmo == 0
    return
  query(gun__owner) <| $ [es] (itemContainer : EidList; human_weap__gunEids : EidList)
    let slotIdx = human_weap__gunEids |> find_index(eid)
    var isMarkGrenade = false
    for itemEid in itemContainer
      query(itemEid) <| $ [es(REQUIRE=item__grenadeType)] (item__id : int; var slot_attach__weaponSlotIdx : int&)
        slot_attach__weaponSlotIdx = -1
        if !isMarkGrenade && item__id == gun__wishAmmoItemType
          slot_attach__weaponSlotIdx = slotIdx
          isMarkGrenade = true


[es(tag=server, track=item__ownerEid, REQUIRE=item__grenadeType)]
def mark_slot_on_dropped_grenades(evt : Event;
                                  item__ownerEid : EntityId;
                                  var slot_attach__weaponSlotIdx : int&)
  if item__ownerEid == INVALID_ENTITY_ID
    slot_attach__weaponSlotIdx = -1
