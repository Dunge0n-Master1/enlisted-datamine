let USA_ICONS = [
  null
  "ui/skin#perks/perk_usa_01.svg"
  "ui/skin#perks/perk_usa_02.svg"
  "ui/skin#perks/perk_usa_03.svg"
  "ui/skin#perks/perk_usa_04.svg"
  "ui/skin#perks/perk_usa_05.svg"
]

let USSR_ICONS = [
  null
  "ui/skin#perks/perk_ussr_01.svg"
  "ui/skin#perks/perk_ussr_02.svg"
  "ui/skin#perks/perk_ussr_03.svg"
  "ui/skin#perks/perk_ussr_04.svg"
  "ui/skin#perks/perk_ussr_05.svg"
]

let GERMANY_ICONS = [
  null
  "ui/skin#perks/perk_ger_01.svg"
  "ui/skin#perks/perk_ger_02.svg"
  "ui/skin#perks/perk_ger_03.svg"
  "ui/skin#perks/perk_ger_04.svg"
  "ui/skin#perks/perk_ger_05.svg"
]

let rankIcons = {
  normandy_allies = USA_ICONS
  normandy_axis   = GERMANY_ICONS
  moscow_allies   = USSR_ICONS
  moscow_axis     = GERMANY_ICONS
  berlin_allies   = USSR_ICONS
  berlin_axis     = GERMANY_ICONS
  tunisia_allies  = USA_ICONS
  tunisia_axis    = GERMANY_ICONS
  stalingrad_allies   = USSR_ICONS
  stalingrad_axis     = GERMANY_ICONS
  pacific_allies   = USA_ICONS
  pacific_axis     = GERMANY_ICONS
}

// ■□▢▣▤
let USSR_GLYPHS = [
  null, "\xE2\x96\xA0", "\xE2\x96\xA1", "\xE2\x96\xA2", "\xE2\x96\xA3", "\xE2\x96\xA4"
]

// ▥▦▧▨▩
let USA_GLYPHS = [
  null, "\xE2\x96\xA5", "\xE2\x96\xA6", "\xE2\x96\xA7", "\xE2\x96\xA8", "\xE2\x96\xA9"
]

// ▪▫▬▭▮
let GERMANY_GLYPHS = [
  null, "\xE2\x96\xAA", "\xE2\x96\xAB", "\xE2\x96\xAC", "\xE2\x96\xAD", "\xE2\x96\xAE"
]

let rankGlyphs = {
  normandy_allies = USA_GLYPHS
  normandy_axis   = GERMANY_GLYPHS
  moscow_allies   = USSR_GLYPHS
  moscow_axis     = GERMANY_GLYPHS
  berlin_allies   = USSR_GLYPHS
  berlin_axis     = GERMANY_GLYPHS
  tunisia_allies  = USA_GLYPHS
  tunisia_axis    = GERMANY_GLYPHS
  stalingrad_allies   = USSR_GLYPHS
  stalingrad_axis     = GERMANY_GLYPHS
  pacific_allies   = USA_GLYPHS
  pacific_axis     = GERMANY_GLYPHS
}

return {
  rankIcons
  rankGlyphs
}
