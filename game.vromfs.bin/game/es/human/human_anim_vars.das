require ecs
require PhysVars

[es(on_appear)]
def init_selected_weapon_var(evt : Event;
                             var human_anim__selectedWeaponVarId : int&;
                             var phys_vars : PhysVars)
  human_anim__selectedWeaponVarId = phys_vars |> registerVar("weapon_selected", 0.0)
