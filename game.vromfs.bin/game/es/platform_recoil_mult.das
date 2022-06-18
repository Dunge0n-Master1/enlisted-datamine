require ecs
require DagorSystem


[es(on_appear)]
def init_recoil_mult_es(evt : Event;
                        var platformRecoilControlMult : float&;
                        var platformDecayUncompensatedRecoil : bool&)
  if get_console_model() != ConsoleModel UNKNOWN
    platformRecoilControlMult = 0.5
    platformDecayUncompensatedRecoil = true

