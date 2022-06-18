options no_aot
require ecs
require DagorConsole


[console_cmd(name="platform_recoil.set_mults", hint="[controlMult] [doDecay] Sets platform dependent recoil multipliers")]
def set_recoil_mult(controlMult : float; doDecay : bool)
  query() <| $ [es] (var platformRecoilControlMult : float&;
                     var platformDecayUncompensatedRecoil : bool&)
    platformRecoilControlMult = controlMult
    platformDecayUncompensatedRecoil = doDecay
