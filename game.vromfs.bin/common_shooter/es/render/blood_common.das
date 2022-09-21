module blood_common shared
require ecs
require DagorMath

def is_blood_enabled()
  var isEnabled = true
  find_query <| $ [es] (isBloodEnabled : bool)
    isEnabled = isBloodEnabled
    return true
  return isEnabled

def get_blood_color()
  var bloodColor = E3DCOLOR(0xFFFFFFFF)
  query() <| $ [es] (isBloodEnabled : bool; disabledBloodColor : E3DCOLOR)
    if !isBloodEnabled
      bloodColor = disabledBloodColor
  return bloodColor
