module daEditor_common shared

require ecs
require strings
require EcsUtils
require DagorDataBlock
require DagorConsole

def editor_select_eid(eid : EntityId; auto_zoom : bool = false)
  console_command("daEd4.selectEid {eid}")
  if auto_zoom
    editor_zoom_selected()

def editor_zoom_selected()
  console_command("daEd4.zoom")

def editor_open(open : bool = true)
  console_command("daeditor.open {open ? 1 : 0}")


def editor_save_entity(eid : EntityId; var blk : DataBlock implicit; override_template_name : string = "")
  var sub = blk |> datablock_add_new_block("entity")
  var tName = empty(override_template_name) ? getEntityTemplateName(eid) : override_template_name
  tName = remove_sub_template_name(tName, "daeditor_selected")
  sub |> datablock_addStr("_template", tName)
  let list = get_active_scene() |> scene_findComponentsList(eid)
  if list != null
    *list |> components_to_blk(*sub, "", false)
  else
    // entity wasn't added to scene
    eid |> components_to_blk(*sub, "", false)