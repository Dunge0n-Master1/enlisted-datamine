let SQUAD_UPGRADES = {
  name = "research/squad_upgrades"
  description = "research/squad_upgrades_desc"
  bg_color = 0xff324b5f
}

let SQUAD_UPGRADES_USSR = SQUAD_UPGRADES.__merge({ icon_id = "squad_ussr" })
let SQUAD_UPGRADES_GER  = SQUAD_UPGRADES.__merge({ icon_id = "squad_germany" })
let SQUAD_UPGRADES_USA  = SQUAD_UPGRADES.__merge({ icon_id = "squad_usa" })
let SQUAD_UPGRADES_JAP  = SQUAD_UPGRADES.__merge({ icon_id = "squad_japan" })

let PERSONELL_UPGRADES = {
  name = "research/personell_upgrades"
  description = "research/personell_upgrades_desc"
  bg_color = 0xff883d3d
}

let PERSONELL_UPGRADES_USSR = PERSONELL_UPGRADES.__merge({ icon_id = "squad_ussr" })
let PERSONELL_UPGRADES_GER  = PERSONELL_UPGRADES.__merge({ icon_id = "squad_germany" })
let PERSONELL_UPGRADES_USA  = PERSONELL_UPGRADES.__merge({ icon_id = "squad_usa" })
let PERSONELL_UPGRADES_JAP  = PERSONELL_UPGRADES.__merge({ icon_id = "squad_japan" })

let WORKSHOP_UPGRADES = {
  name = "research/army_workshop_upgrades"
  description = "research/army_workshop_upgrades_desc"
  bg_color = 0xff808054
}

let WORKSHOP_UPGRADES_USSR = WORKSHOP_UPGRADES.__merge({ icon_id = "squad_ussr" })
let WORKSHOP_UPGRADES_GER  = WORKSHOP_UPGRADES.__merge({ icon_id = "squad_germany" })
let WORKSHOP_UPGRADES_USA  = WORKSHOP_UPGRADES.__merge({ icon_id = "squad_usa" })
let WORKSHOP_UPGRADES_JAP  = WORKSHOP_UPGRADES.__merge({ icon_id = "squad_japan" })

return freeze({
  berlin_allies = [
    SQUAD_UPGRADES_USSR
    PERSONELL_UPGRADES_USSR
    WORKSHOP_UPGRADES_USSR
  ]
  berlin_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  moscow_allies = [
    SQUAD_UPGRADES_USSR
    PERSONELL_UPGRADES_USSR
    WORKSHOP_UPGRADES_USSR
  ]
  moscow_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  normandy_allies = [
    SQUAD_UPGRADES_USA
    PERSONELL_UPGRADES_USA
    WORKSHOP_UPGRADES_USA
  ]
  normandy_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  tunisia_allies = [
    SQUAD_UPGRADES_USA
    PERSONELL_UPGRADES_USA
    WORKSHOP_UPGRADES_USA
  ]
  tunisia_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  stalingrad_allies = [
    SQUAD_UPGRADES_USSR
    PERSONELL_UPGRADES_USSR
    WORKSHOP_UPGRADES_USSR
  ]
  stalingrad_axis = [
    SQUAD_UPGRADES_GER
    PERSONELL_UPGRADES_GER
    WORKSHOP_UPGRADES_GER
  ]
  pacific_allies = [
    SQUAD_UPGRADES_USA
    PERSONELL_UPGRADES_USA
    WORKSHOP_UPGRADES_USA
  ]
  pacific_axis = [
    SQUAD_UPGRADES_JAP
    PERSONELL_UPGRADES_JAP
    WORKSHOP_UPGRADES_JAP
  ]
})