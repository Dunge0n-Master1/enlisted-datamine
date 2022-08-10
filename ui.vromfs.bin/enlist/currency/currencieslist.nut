from "%enlSqGlob/ui_library.nut" import *

let { currenciesList } = require("%enlist/currency/currencies.nut")
let { get_circuit_conf } = require("app")

const SHOP_CATEGORY_URL_DEFAULT = "https://store.gaijin.net/catalog.php?category={category}"    //warning disable: -forgot-subst
let shopCategoryUrl = get_circuit_conf()?.shopCategoryUrl ?? SHOP_CATEGORY_URL_DEFAULT

let enlistedGold = freeze({
  id = "EnlistedGold"
  image = @(size) "ui/skin#currency/enlisted_gold.svg:{0}:{0}:K".subst(size.tointeger())
  locId = "currency/code/EnlistedGold"
  purchaseUrl = shopCategoryUrl.subst({ category = "EnlistedGold" })
  qrDesc = "currency/code/qr/EnlistedGoldConsoles"
  qrConsoleUrl = "{0}&partner=QRLogin&partner_val=q37edt1l".subst(
    shopCategoryUrl.subst({ category = "EnlistedGoldConsoles" }))
})

currenciesList([enlistedGold])

return {
  enlistedGold
}
