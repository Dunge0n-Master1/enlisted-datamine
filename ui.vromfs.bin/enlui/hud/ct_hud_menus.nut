from "%enlSqGlob/ui_library.nut" import *

let {hudIsInteractive} = require("state/interactive_state.nut")

let hudMenusContainer = {value = null}

let hudMenusGen = Watched(0)

let function hudMenus(menus){
  hudMenusGen(hudMenusGen.value+1)
  hudMenusContainer.value = menus
}
let getHudMenus = @() hudMenusContainer.value


/*
Example: inventory.group = 3, chatInput.group = 4, pieMenu.group = 5
case 1
  requested: piemenu(5), opened: chat(4)
  result = nothing
case 2
  requested: inventory(3), opened: piemenu (4)
  result = piemenu closed, inventory opened
*/

let function closeMenu_int(menu){
  if (menu?.show.value == true)
    log($"HudMenus: Close {menu.id}")
  if ("close" in menu)
    menu.close()
  else
    menu.show(false)
}

let function openMenu_int(menu, menusDescr){
  log($"HudMenus: Open {menu.id}")
  let requestedMenuGroup = menu?.group ?? 100
  let curOpenMenus = []
  foreach (other in menusDescr) {
    if (!other?.show.value || other.id == menu.id)
      continue
    let foundGroup = (other?.group ?? 100)
    if (requestedMenuGroup > foundGroup)
      return
    curOpenMenus.append(other)
  }
  if (menu?.open != null)
    menu.open()
  else
    menu.show(true)
  curOpenMenus.each(@(v) closeMenu_int(v))
}
let function closeMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  closeMenu_int(menu)
}

let function openMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  openMenu_int(menu, menusDescr)
}

let function setMenuVisibility(id, isVisible){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  if (isVisible)
    openMenu_int(menu, menusDescr)
  else
    closeMenu_int(menu)
}

let function switchMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  if (!menu.show.value){
    openMenu_int(menu, menusDescr)
  }
  else
    closeMenu_int(menu)
}

let function mkMenuEventHandlers(menu) {
  let eventName = menu?.event
  let holdToToggleDurMsec = menu?.holdToToggleDurMsec ?? 500
  if (!( menu?.show instanceof Watched) && !("close" in menu && "open" in menu))
    return {}

  let function endEvent(event){
    if ((event?.dur ?? 0) > holdToToggleDurMsec || event?.appActive==false)
      closeMenu_int(menu)
  }
  return {
    [eventName] = @(_event) switchMenu(menu.id),
    [$"{eventName}:end"] = endEvent
  }
}

let function menusUi() {
  let watch = [hudMenusGen, hudIsInteractive]
  let children = []
  let eventHandlers = {}

  let menus_descr = getHudMenus() ?? []
  foreach (menu in menus_descr) {
    if (menu?.event != null) {
      eventHandlers.__update(mkMenuEventHandlers(menu))
    }
    if (menu?.show instanceof Watched) {
      watch.append(menu.show)
      if (menu?.show?.value)
        children.append(menu?.menu)
    } else {
      children.append(menu?.menu)
    }
  }

  return {
    size = flex()
    watch
    children
    eventHandlers
  }
}

return {
  hudMenus
  openMenu
  closeMenu
  setMenuVisibility
  switchMenu
  menusUi
  getHudMenus
}
