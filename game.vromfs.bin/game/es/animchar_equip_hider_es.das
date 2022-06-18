require ecs
require PhysVars

[es(on_appear, tag=render, before=anim_phys_init_es)]
def torso_hider_init_es(evt : Event; char_flags__hasBodyArmorOn : bool; var char_flags__bodyArmorWearVarId : int&; var phys_vars : PhysVars)
  char_flags__bodyArmorWearVarId = registerVar(phys_vars, "wears_body_armor", char_flags__hasBodyArmorOn ? 1.0 : 0.0)

[es(tag=render, track=char_flags__hasBodyArmorOn)]
def torso_hider_es(evt : Event; char_flags__hasBodyArmorOn : bool; char_flags__bodyArmorWearVarId : int; var phys_vars : PhysVars)
  setVar(phys_vars, char_flags__bodyArmorWearVarId, char_flags__hasBodyArmorOn ? 1.0 : 0.0)

