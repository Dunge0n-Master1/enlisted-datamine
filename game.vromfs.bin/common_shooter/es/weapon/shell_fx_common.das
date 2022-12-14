module shell_fx_common shared

require ecs
require ecs.safe
require DagorSystem
require PhysMat
require Dacoll

def private get_floor_material_name(pos : float3; fx_trace_length : float)
  var matId = 0
  var t = fx_trace_length
  tracedown_normalized(pos, t, matId, ETF_ALL)

  return get_material_name(get_material(matId))

def private get_fx_name(mat_name : string;
                        fx_default : string;
                        fx_info : Object const?)
  let obj = fx_info?[mat_name] ?as Object
  return obj?.fx ?? fx_default

def get_fx_name_based_on_floor(pos : float3;
                               fx_info_eid : EntityId;
                               is_under_water : bool)
  var res : string

  query(fx_info_eid) <| $ [es] (shell_explosion_fx__traceLength : float;
                                shell_explosion_fx__default : string;
                                shell_explosion_fx__info : Object const?;
                                shell_explosion_fx__tracePosOffset : float3 = float3())
    let matName = is_under_water ? "water3d" : get_floor_material_name(pos + shell_explosion_fx__tracePosOffset, shell_explosion_fx__traceLength)
    res = get_fx_name(matName, shell_explosion_fx__default, shell_explosion_fx__info)

  return res

def get_fx_name_based_on_floor(pos : float3;
                               fx_info_template_name : string;
                               is_under_water : bool)
  let fxInfoEid = getSingletonEntity(fx_info_template_name)
  return get_fx_name_based_on_floor(pos, fxInfoEid, is_under_water)

def get_adjusted_pos_for_effect(pos : float3; var is_under_water : bool&)
  var waterLevel = 0.0
  is_under_water = traceht_water(pos, waterLevel) && pos.y < waterLevel

  return float3(pos.x, is_under_water ? waterLevel : pos.y, pos.z)
