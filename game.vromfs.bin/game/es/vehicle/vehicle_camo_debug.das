options no_aot
require ecs
require ecs.common
require ecs.safe
require DagorConsole

[console_cmd(name="vehicle.camo_set")]
def vehicle_camo_set_cmd(camo_name : string)
  query() <| $ [es(REQUIRE=hero)] (human_use_object__selectedObject : EntityId)
    query(human_use_object__selectedObject) <| $ [es] (eid : EntityId; skin__template : string; var animchar__objTexReplace : Object)
      let skinsTemplate = skin__template |> getTemplateByName
      if skinsTemplate == null
        console_print("skin__template isn't exist on this vehicle!")
        return

      let unlocks = *skinsTemplate |> getTemplateComponent("skin__unlock") |> get_ecs_StringList
      let objTexReplace = *skinsTemplate |> getTemplateComponent("skin__objTexReplace") ?as Array
      if objTexReplace == null || unlocks == null
        console_print("Camo template {skin__template} doesn't have skin.unlock or skin.objTexReplace component")
        return

      let idx = *unlocks |> find_index(camo_name)
      if idx < 0
        console_print("Camo <{camo_name}> not exist for vehicle <{getEntityTemplateName(eid)}>")
        return

      animchar__objTexReplace := *(objTexReplace?[idx] ?as Object)
