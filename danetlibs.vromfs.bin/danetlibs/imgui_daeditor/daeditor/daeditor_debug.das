options no_aot
require ecs
require math.base
require strings
require daslib/strings_boost
require danetlibs.imgui_daeditor.daeditor.daEditor_common
require DagorConsole
require DagorEditor
require danetlibs.console_commands.main.console_common


[console_cmd(name="daEd4.select")]
def daeditor_select(eid : uint; auto_zoom : bool = true)
  if doesEntityExist(EntityId(eid))
    editor_open()
    editor_select_eid(EntityId(eid))
    if auto_zoom
      entity_object_editor_zoomAndCenter()
  else
    console_print("{eid}: non-existent entity")


[console_processor]
def daeditor_select_processor(args : array<string>;
                              collect : bool;
                              var hints : ConsoleProcessorHints)
  if !collect
    return false

  let cmd = "daEd4.select"
  let inputs <- args[0] |> split(" ")
  let hintsCount = 20

  if length(inputs) >= 2 && inputs[0] == cmd
    let entities <- find_console_hint_entities(inputs[1], /*threshold_cam_distance_sq*/ square(50.0), hintsCount)

    for i in range(min(length(entities), hintsCount))
      hints |> add_hint("{cmd} {entities[i].eid}", 0, 1, "[auto_zoom]", build_entity_hint_desc(entities[i]))
  return false
