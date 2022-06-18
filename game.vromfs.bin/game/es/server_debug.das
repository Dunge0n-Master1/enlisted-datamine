options no_aot
require DagorConsole
require game.es.server_debug_common


[console_cmd(name="server.cmd", is_hook=true)]
def do_server_cmd(cmd : string; arg1 : string = ""; arg2 : string = ""; arg3 : string = ""; arg4 : string = ""; arg5 : string = "";
                  arg6 : string = ""; arg7 : string = ""; arg8 : string = ""; arg9 : string = ""; arg10 : string = ""; arg11 : string = "")
  let message = "{cmd} {arg1} {arg2} {arg3} {arg4} {arg5} {arg6} {arg7} {arg8} {arg9} {arg10} {arg11}"
  exec_server_cmd(message)

