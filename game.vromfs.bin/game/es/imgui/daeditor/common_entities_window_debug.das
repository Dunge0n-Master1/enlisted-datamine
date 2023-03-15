options no_aot
require ecs
require imgui
require DagorImgui
require DagorEditor
require danetlibs.imgui_daeditor.daEditor.daEditor_common


def entity_button(name : string; eid : EntityId)
  if imgui::Button("{name} ({eid})")
    if eid != INVALID_ENTITY_ID
      editor_select_eid(eid, true)

  if IsItemHovered()
    BeginTooltip()
    TextUnformatted(eid != INVALID_ENTITY_ID ? getEntityTemplateName(eid) : "None")
    EndTooltip()


[imgui_window(name="Common Entities", group="Editor")]
def editor_common_entities_debug_window()

  init_entity_object_editor()

  query <| $ [es(REQUIRE=localPlayer)] (eid : EntityId)
    entity_button("Local Player", eid)

  query() <| $ [es] (eid : EntityId;
                     camera__active : bool)
    if camera__active
      entity_button("Active Camera", eid)

  query() <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId;
                                           squad_member__squad : EntityId = INVALID_ENTITY_ID;
                                           human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                                           human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                                           human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                                           human_vehicle__occupiedSeatEid : EntityId = INVALID_ENTITY_ID)
    imgui::Text("Watched Hero:")
    entity_button("Hero", eid)
    entity_button("Squad", squad_member__squad)

    entity_button("Current Gun", human_weap__currentGunEid)
    entity_button("Stationary Gun", human_attached_gun__attachedGunEid)

    entity_button("Vehicle", human_anim__vehicleSelected)
    entity_button("Vehicle Seat", human_vehicle__occupiedSeatEid)

    query(human_anim__vehicleSelected) <| $ [es] (cockpit__eid : EntityId)
      entity_button("Vehicle Cockpit", cockpit__eid)

