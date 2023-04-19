require ecs
require PhysMat
require HumanPhys
require DngHuman
require DngDm

[es(tag=server, on_appear)]
def barbwire_mat_damage_init(evt : Event; barbwire_damage__matName : string; var barbwire_damage__matId : int&)
  barbwire_damage__matId = get_material_id(barbwire_damage__matName)

[es(tag=server, no_order)]
def barbwire_mat_damage(info : UpdateStageInfoAct;
                        eid : EntityId;
                        transform : float3x4;
                        human_net_phys : HumanActor;
                        barbwire_damage__matId : int;
                        barbwire_damage__damagePerSecond : float)
  assume phys = human_net_phys.phys
  assume previousState = phys.previousState
  assume currentState = phys.currentState
  let matId = currentState.torsoContactMatId

  if matId == barbwire_damage__matId
    let isChangingPos = abs(currentState.heightCurVel) > 1.0
    let isRotating = length_sq(currentState.targetGunSpd) > 1.0
    let isMoving = length_sq(currentState.velocity) > 0.01
    let isChangingWeapon = currentState.weapEquipState.curState != HUWeaponEquipState EES_EQUIPED
    let isChangingLean = abs(currentState.leanPosition - previousState.leanPosition) > 0.1
    if isRotating || isChangingPos || isMoving || isChangingWeapon || isChangingLean
      let damage = info.dt * barbwire_damage__damagePerSecond
      let dmDesc = DamageDesc(DamageType DM_BARBWIRE, damage, transform[3])
      damage_entity(eid, eid, dmDesc)
