let {get_setting_by_blk_path} = require("settings")
let {file_exists} = require("dagor.fs")
let {Watched, Computed} = require("frp")
let { get_game_name, get_circuit_conf, get_circuit, get_exe_version, get_build_number } = require("app")

let circuit = Watched(get_circuit())
let exe_version = Watched(get_exe_version())
let build_number = Watched(get_build_number())

//fixme: probably should be done differently in dedicated, I guess yup file is not accessable there and in anywhere it has different name
//fixme: this is not correct in consoles, cause there are version for vroms (no api yet to get) and for main game
let project_yup_name = get_setting_by_blk_path("yupfile") ?? "{0}.yup".subst(get_game_name())
let yup_version = Watched(file_exists(project_yup_name)
  ? require("yupfile_parse").getStr(project_yup_name, "yup/version")
  : null)

let circuitEnv = Watched(get_circuit_conf()?.environment ?? "")
let version = Computed(@() yup_version.value ?? exe_version.value)
//FIXME - for unknown reason in internal tests (at least in dev exe circuitEnv=="")
let isProductionCircuit = Computed(@() !(circuitEnv.value!="production"))
let isInternalCircuit = Computed(@() circuitEnv.value=="test")

return {
  version,
  isProductionCircuit,
  isInternalCircuit,
  project_yup_name = Watched(project_yup_name),
  yup_version,
  exe_version,
  build_number,
  circuit,
  circuit_environment = circuitEnv
}
