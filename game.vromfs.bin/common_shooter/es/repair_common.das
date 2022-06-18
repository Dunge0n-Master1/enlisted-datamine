module repair_common shared

require ecs
require dm
require EnlistedDm

def repair_vehicle(recovery_ratio : float;
                   var meta_parts_state : MetaPartsState&;
                   var damage_model : DamageModel&;
                   var fire_protection : FireProtection&)
  var repairRequired = false
  for part in damage_model.dmData.parts
    let partId = get_damage_part_id(part)
    assume fire_protection_part = fire_protection[partId]
    var hp = uint16(0)
    part.relHpFixed = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(part.relHpFixed) + float(recovery_ratio))
    part.state = (DamagePartState DP_STATE_DAMAGED)
    if int(part.relHpFixed) > HP_DAMAGED_STATE_TRESHOLD_FIXED
      part.state = (DamagePartState DP_STATE_NORMAL)
    if fire_protection_part.maxHp > 0.f
      hp = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(fire_protection_part.hpFixed) + float(recovery_ratio))
    fire_protection_part.hpFixed = hp
    repairRequired = int(part.relHpFixed) < MAX_REL_HP_FIXED
  for i in range(0, int(get_meta_part_size(meta_parts_state)))
    repair_meta_part(meta_parts_state, i, recovery_ratio)
    repairRequired = int(get_meta_part_rel_hp(meta_parts_state, i)) < MAX_REL_HP_FIXED
  return repairRequired
