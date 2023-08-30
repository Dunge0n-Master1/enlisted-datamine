module inventory_drop_common shared
require ecs
require ecs.common
require net
require math.base
require DagorRandom
require DagorMath
require strings
require Dacoll
require PhysMat
require inventory
require DagorSystem
require DngNet
require game.es.events


def align_item2(pos : float3;
                norm : float3;
                var tm : float3x4&)
  tm[1] = norm
  tm[0] = get_normal(tm[1])
  tm[2] = normalize(cross(tm[0], tm[1]))
  tm[3] = pos
  var rotTm = IDENT_TM
  rotyTM(rnd_float(0.0, TWOPI), rotTm)
  tm = tm * rotTm


def align_item2(pos : float3;
                var aligned_tm : float3x4&)
  let from = pos + float3(0.f, 0.05f, 0.f)
  let dir = float3(0, -1, 0)
  var t = 1.0f
  var norm = float3()
  if !traceray_normalized(from, dir, t, norm)
    norm = float3(0, 1, 0)
  align_item2(pos, norm, aligned_tm)


def drop_item_on_ground2(var pos_tm : float3x4&)
  var height = 300.f
  let dropOffset = float3(0.f, 0.05f, 0.f)
  var norm = float3(0, 1, 0)
  var pos = pos_tm[3] + dropOffset
  let matId = get_material_id("itemDropRayMat")
  if tracedown_normalized_with_mat_id(pos, height, norm, ETF_DEFAULT, matId)
    pos.y -= height
  else
    let lmeshHeight = traceht_lmesh(pos)
    if lmeshHeight > -1e5f
      pos.y = lmeshHeight
  align_item2(pos, norm, pos_tm)


struct SimpleItemDesc
  id : int
  eid : EntityId
  ownerEid : EntityId
  tm : float3x4
  templOverride : string
  addTemplate : string
  skipArrange : bool
  ignoreChestAndDropOnGround : bool
  gunSlot : int // gunSlot == -1 for not equipped guns and not gun items


def drop_item_without_props(desc : ItemDesc | SimpleItemDesc;
                            var comps : ComponentsInitializer;
                            loot_cleanup_time : float = -1.0f;
                            is_already_looted : bool = true;
                            container_eid : EntityId = INVALID_ENTITY_ID)
  var addTemplate = desc.addTemplate
  var itemTemplate = desc.templOverride

  var itemDropItem = desc.tm
  drop_item_on_ground2(itemDropItem)

  comps |> set("transform", itemDropItem)
  comps |> set("item__ownerEid", INVALID_ENTITY_ID)
  comps |> set("item__lastOwner", desc.ownerEid)
  if container_eid != INVALID_ENTITY_ID
    comps |> set("item__parentContainerEid", container_eid)
  if desc.eid != INVALID_ENTITY_ID
    if !doesEntityExist(desc.eid)
      logwarn("drop_item_without_props ignore attempt to drop non existing entity item {desc.eid}")
      return
    comps |> set("slot_attach__attachedTo", INVALID_ENTITY_ID)
    query(desc.eid) <| $ [es] (item__recreateInInventory : string = "";
                               item__recreateInEquipment : string = "base_vis_item";
                               item__recreateOnGround : string = "item_in_world";
                               var item__isOnGround : bool?)
      if item__isOnGround != null
        *item__isOnGround = true
      let templateToAdd = container_eid != INVALID_ENTITY_ID ? "item_in_container" : item__recreateOnGround
      var newTemplateName = getEntityTemplateName(desc.eid)
      if !empty(item__recreateInInventory)
        newTemplateName = newTemplateName |> remove_sub_template_name(item__recreateInInventory)
      if !empty(item__recreateInEquipment)
        newTemplateName = newTemplateName |> remove_sub_template_name(item__recreateInEquipment)
      if !empty(templateToAdd)
        newTemplateName = newTemplateName |> add_sub_template_name(templateToAdd)
      remote_recreate_entity_from(desc.eid, newTemplateName) <| $(init)
        init := comps
    return

  if empty(itemTemplate)
    logerr("Cannot determine template to drop (addTemplate={addTemplate})")
    return

  if container_eid != INVALID_ENTITY_ID && !empty(addTemplate)
    addTemplate = "item_in_container"

  if !empty(addTemplate)
    itemTemplate = itemTemplate |> add_sub_template_name(addTemplate)

  comps |> set("item__alreadyLooted", is_already_looted)
  comps |> set("ownerEid", desc.ownerEid)
  comps |> set("item__isOnGround", true)

  comps |> set("drop_item_cb__lootCleanupTime", loot_cleanup_time)
  itemTemplate = itemTemplate |> add_sub_template_name("drop_item_cb")
  createEntity(itemTemplate, comps)


def drop_item_with_props(desc : ItemDesc;
                         var comps : ComponentsInitializer;
                         loot_cleanup_time : float = -1.0f;
                         is_already_looted : bool = true;
                         container_eid : EntityId = INVALID_ENTITY_ID)
  let customSkin = desc.customSkin
  if !empty(customSkin)
    comps |> set("gun__customSkin", customSkin)

  if desc.eid == INVALID_ENTITY_ID
    if !empty(desc.customProps)
      comps |> set("customProps", desc.customProps)

    using <| $(var modTemplates : StringList)
      get_mod_templates(desc) <| $(modTemplate : string)
        if !empty(modTemplate)
          modTemplates |> push(modTemplate)
      comps |> set("drop_item_cb__modTemplates", modTemplates)

  drop_item_without_props(desc, comps, loot_cleanup_time, is_already_looted, container_eid)


def drop_item2(item : ItemDesc;
               loot_cleanup_time : float = -1.0f;
               is_already_looted : bool = true;
               container_eid : EntityId = INVALID_ENTITY_ID)
  using() <| $(var comps : ComponentsInitializer)
    drop_item_with_props(item, comps, loot_cleanup_time, is_already_looted, container_eid)


def try_put_item2(from : float3;
                  pos : float3;
                  var tm : float3x4&)
  let dir = normalize(pos - from)
  var norm = float3()
  var t = 10.0f
  let slope = 0.25f
  if traceray_normalized(from, dir, t, norm) && norm.y > slope
    align_item2(from + dir * t, norm, tm)
    return true
  return false


def remove_entity_from_container(var container : EidList;
                                 eid : EntityId)
  let idx = container |> find_index(eid)
  if idx < 0
    return false
  container |> erase(idx)
  return true


def drop_item_from_cont2(eid : EntityId;
                         item_eid : EntityId)
  if is_server()
    query(eid) <| $ [es] (transform : float3x4;
                          var itemContainer : EidList&;
                          human_inventory__dropLootOffset : float3;
                          human_inventory__dropsLoot : bool = true)
      if remove_entity_from_container(itemContainer, item_eid)
        if human_inventory__dropsLoot
          using() <| $(var desc : ItemDesc)
            desc.eid = item_eid
            desc.ownerEid = eid
            desc.tm = transform
            desc.tm[3] = transform * human_inventory__dropLootOffset
            drop_item2(desc)
        else
          destroyEntity(item_eid)
        eid |> sendEvent([[EventOnLootDrop itemEid=item_eid]])
  else
    eid |> send_net_event([[HumanDropItemRequest itemEid=item_eid]])
    eid |> sendEvent([[EventOnLootDrop itemEid=item_eid]])
