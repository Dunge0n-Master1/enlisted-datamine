require ecs
require PhysVars

[es(on_appear, tag=render, before=anim_phys_init_es)]
def hair_hider_init_es(evt : Event; char_flags__hasHeadwearOn : bool; var char_flags__headwearVarId : int&; var phys_vars : PhysVars)
  char_flags__headwearVarId = registerVar(phys_vars, "wears_hat", char_flags__hasHeadwearOn ? 1.0 : 0.0)

[es(tag=render, track=char_flags__hasHeadwearOn)]
def hair_hider_es(evt : Event; char_flags__hasHeadwearOn : bool; char_flags__headwearVarId : int; var phys_vars : PhysVars)
  setVar(phys_vars, char_flags__headwearVarId, char_flags__hasHeadwearOn ? 1.0 : 0.0)
