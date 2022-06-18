module mortar_common shared
require ecs
require DagorSystem
require DaWeaponProps
require Gun

def get_shell_speed(shellPropsId : ShellPropIds) : float
  var speed = 50.0
  shell_start_get_props(int(shellPropsId.shellId)) <| $(shellStartProps : ShellStartProps)
    speed = shellStartProps.speed
  return speed

def get_shoot_pos(gun : Gun; gloc : GunLocation)
  var shootTm : float3x4
  let visTm : float3x4 const? = gloc.visTm
  let physTm : float3x4 const? = gloc.physTm
  gun_calculate_shoot_tm(gun, gloc.gunShootDir, gloc.gunPos, visTm, physTm, shootTm)
  return shootTm[3]