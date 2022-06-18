require ecs
require game.es.events
require game.es.inventory_common

[es(tag=server, before=useful_box_use_finish_es)]
def item_box_use_es(evt : CmdUseUsefulBox;
                    useful_box__giveItem : string;
                    var useful_box__successUse : bool&;
                    var useful_box__requiredUseCount : int&;
                    useful_box__itemExistTag : string = "")
  useful_box__successUse = true
  useful_box__requiredUseCount = 1

  if useful_box__itemExistTag == "" // tag empty, player can take any amount of item
    evt.requesterEid |> push_item_in_cont(useful_box__giveItem)
    return

  query(evt.requesterEid) <| $ [es] (itemContainer : EidList)
    for itemEid in itemContainer
      if has(itemEid, useful_box__itemExistTag)
        useful_box__successUse = false
        return
    evt.requesterEid |> push_item_in_cont(useful_box__giveItem)

[es(tag=server, after=item_box_use_es, before=useful_box_use_finish_es, REQUIRE=useful_box__giveItem)]
def item_box_use_finish_es(evt : CmdUseUsefulBox; useful_box__successUse : bool; useful_box__hintItemFull : string)
  if !useful_box__successUse
    sendEvent(evt.requesterEid, [[CmdHeroLogEvent event="item_is_full", text=useful_box__hintItemFull]])
