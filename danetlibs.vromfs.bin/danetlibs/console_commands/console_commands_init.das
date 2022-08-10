options no_aot

require ecs
require ecs.fs
require app
require ECSGlobalTags


[export, unused_argument(base_path)]
def load_console_commands(base_path : string) : bool
  var ok = true

  if typeinfo(builtin_module_exists DagorConsole)
    ok = load_sub_folder(base_path, "main") && ok

  return ok


[export]
def test()
  let ok = load_console_commands("%danetlibs/console_commands")
  assert(ok)
