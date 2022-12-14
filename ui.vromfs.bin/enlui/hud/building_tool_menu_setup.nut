import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {
  buildingToolMenuItems, showBuildingToolMenu, elemSize
} = require("%ui/hud/state/building_tool_menu_state.nut")
let {
  isBuildingToolMenuAvailable, buildingUnlocks, buildingTemplates, availableBuildings,
  availableStock, requirePrice, buildingAllowRecreates
} = require("%ui/hud/state/building_tool_state.nut")
let mkPieItemCtor = require("%ui/hud/components/building_tool_menu_item_ctor.nut")
let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

let function selectBuildingType(index) {
  let weapEid = ecs.obsolete_dbg_get_comp_val(controlledHeroEid.value, "human_weap__currentGunEid", ecs.INVALID_ENTITY_ID)
  ecs.client_send_event(weapEid, ecs.event.CmdSelectBuildingType({index=index}))
}

let svg = memoize(function(img) {
  return "!ui/uiskin/{0}.svg:{1}:{1}:K".subst(img, elemSize.value[1])
})

let updateBuildingsPie = function (templates) {
  buildingToolMenuItems(templates.map(function (templateName, index) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)

    let blockedByUnlock = buildingUnlocks?.value.findindex(@(v) v == index) == null
    if (blockedByUnlock)
      return null
    let text = template?.getCompValNullable?("building_menu__text") ?? ""
    let imageName = template?.getCompValNullable?("building_menu__image")
    let image = imageName ? svg(imageName) : null
    let buildCount = Computed(@() availableBuildings.value?[index] ?? 0)
    let allowRecreate = Computed(@() buildingAllowRecreates.value?[index] ?? false)

    let buildingCostText = Computed(@() "\n\n".concat(
      loc("buildingMenu/resourcesRequire", {count=requirePrice?.value[index] ?? 0}),
      loc("buildingMenu/availableResources", {count=availableStock.value}))
    )

    let hintText = Computed(@() "\n\n".concat(loc(text), buildingCostText.value))
    let noRequirementResources = Computed(@() (requirePrice?.value[index] ?? 0) > availableStock.value)
    return {
      action = @() selectBuildingType(index)
      disabledAction = @() showMsg(noRequirementResources.value ? loc("msg/buildTypeLimitResourse") : loc("msg/buildTypeLimitReached"))
      text = hintText
      disabledtext = Computed(@() "{text} \n\n {buildingCostText}".subst({
        text=loc("buildingMenu/buildTypeLimitReached"),
        buildingCostText=buildingCostText.value}))
      available = Computed(@() (allowRecreate.value || buildCount.value > 0) && !noRequirementResources.value)
      closeOnClick = true
      ctor = mkPieItemCtor(index, image, elemSize.value)
    }
  }).filter(@(v) v != null))
  if (templates.len() == 0)
    showBuildingToolMenu(false)
}

buildingUnlocks.subscribe(@(_) updateBuildingsPie(buildingTemplates.value))

buildingTemplates.subscribe(updateBuildingsPie)


isBuildingToolMenuAvailable.subscribe(function(isAvailable) { if (!isAvailable) showBuildingToolMenu(false) })
