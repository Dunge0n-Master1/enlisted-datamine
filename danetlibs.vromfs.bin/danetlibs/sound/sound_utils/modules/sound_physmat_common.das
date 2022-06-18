module sound_physmat_common shared

require ecs
require soundSystem

def get_sound_step_material_id(pmid : int) : float
  var smid = -1.
  find_query() <| $ [es(REQUIRE=soundStepSettings)] (sound_physmat__PMIDToSMID : FloatList; sound_physmat__defSoundMatId : float)
    smid = uint(pmid) < uint(length(sound_physmat__PMIDToSMID)) ? sound_physmat__PMIDToSMID[pmid] : sound_physmat__defSoundMatId
    return true
  if smid < 0.
    sound_debug("sound_step_settings is missing or not properly inited")
  return smid

def get_projectile_sound_material_id(pmid : int) : float
  var smid = -1.
  find_query() <| $ [es(REQUIRE=projectileSoundPhysmat)] (sound_physmat__PMIDToSMID : FloatList; sound_physmat__defSoundMatId : float)
    smid = uint(pmid) < uint(length(sound_physmat__PMIDToSMID)) ? sound_physmat__PMIDToSMID[pmid] : sound_physmat__defSoundMatId
    return true
  if smid < 0.
    sound_debug("projectile_sound_physmat is missing or not properly inited")
  return smid
