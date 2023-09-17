module cannon_resupply_common shared

require ecs
require DagorMath


struct CannonShellInfo
  max : int
  current : int


def get_turrets_shell_info(gunEids : EidList)
  var info = [[CannonShellInfo max=0, current=0]]
  for gunEid in gunEids
    query(gunEid) <| $ [es] (gun__shellsAmmo : Array; gun__ammo_by_shell : IntList)
      for ammoByShell, shellsAmmo in gun__ammo_by_shell, gun__shellsAmmo
        info.max += get_int(shellsAmmo) ?? 0
        info.current += ammoByShell
  return info


def calculate_resupply_cost(shell_info : CannonShellInfo; building_cost : float; resupply_cost_percent : float)
  let percent = (1f - safediv(float(shell_info.current), float(shell_info.max)))
  return building_cost * percent * resupply_cost_percent
