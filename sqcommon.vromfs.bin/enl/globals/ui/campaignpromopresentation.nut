
const CAMPAIGN_STALINGRAD_FREEMIUM = 1
const CAMPAIGN_PACIFIC_PASS = 2

let campaignConfigs = freeze({
  [CAMPAIGN_STALINGRAD_FREEMIUM] = {
    locBase = "freemium"
    backImage = "ui/gameImage/freemium_bg.jpg"
    widgetIcon = "!ui/uiskin/currency/enlisted_freemium.svg:{0}:{0}:K"
    widgetImage = "ui/uiskin/offers/freemium_widget.jpg"
    color = 0xFF584AA3
    darkColor = 0xFF3F3187
  },
  [CAMPAIGN_PACIFIC_PASS] = {
    locBase = "pacific"
    backImage = "ui/gameImage/bundel_bg_pacific.jpg"
    widgetIcon = "!ui/uiskin/currency/enlisted_pacific.svg:{0}:{0}:K"
    widgetImage = "ui/uiskin/offers/bundle_bg_pacific_small.jpg"
    color = 0xFF34911E
    darkColor = 0xFF256715
  }
})

let getConfig = @(groupId) campaignConfigs?[groupId] ?? {}

return {
  getConfig
}