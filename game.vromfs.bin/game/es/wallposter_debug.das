options no_aot
require ecs
require ecs.common
require game.es.net_console_macro
require daslib/strings_boost
require danetlibs.console_commands.main.console_common


[net_console_cmd(name="wallposter.add", hint="Add a wallposter with given template name to a player")]
def add_wallposter_to_player_cmd(wallposter_template : string; [[net_player]] player_eid : EntityId)
  query(player_eid) <| $ [es] (var wallPosters__maxCount : int&; var wallPosters : Array&)
    push_to_array(wallPosters) <| $(var obj : Object)
      obj |> set("template", wallposter_template)
    wallPosters__maxCount += 1

[console_processor]
def add_wallposter_to_player_cmd_processor(args : array<string>;
                                           collect : bool;
                                           var hints : ConsoleProcessorHints)
  let cmd = "wallposter.add"
  if collect
    let inputs <- args[0] |> split(" ")
    if length(inputs) >= 1
      add_hints([[auto[] [[CommandArgDesc name="wallposter_template", hintType=CommandArgHintType TemplateName]] ]],
                cmd, inputs, /*hints_count*/ 20, /*threshold_cam_distance_sq*/ 2500.0, hints)
  return false
