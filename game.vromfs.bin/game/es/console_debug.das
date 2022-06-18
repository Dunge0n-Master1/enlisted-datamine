options no_aot
require DagorConsole
require daslib/strings_boost


[console_processor]
def history_completion(args : array<string>;
                       collect : bool;
                       var hints : ConsoleProcessorHints)
  let cmd = "/"
  if collect
    if starts_with(args[0], "{cmd} ")
      console_get_command_history() <| $(list)
        let search = args[0] |> slice(1, length(args[0])) |> strip()
        for it in list
          if length(search) == 0 || find(it, search) >= 0
            hints |> add_hint("{cmd} {it}", 1, 1, "")
  elif args[0] == cmd
    let newCmd = build_string() <| $(str)
      let n = length(args)
      for i in range(1, n)
        str |> write(args[i])
        if i < n - 1
          str |> write(" ")
    if console_top_history_command() |> starts_with(args[0])
      console_pop_front_history_command()
    console_add_history_command(newCmd)
    console_command(newCmd)
    return true

  return false
