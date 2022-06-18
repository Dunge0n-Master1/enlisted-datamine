// Race isn't animchar param. Only for faceGen
let EUROPEAN = 0
let ASIAN = 1
let AFRICAN = 2

let genFacesOverrides = {
  head_01_ger_summer_facegen_char = { race = EUROPEAN }
  head_01_us_summer_facegen_char = { race = EUROPEAN }
  head_01_ussr_summer_facegen_char = { race = EUROPEAN }
  head_35_facegen_char = { race = ASIAN }
  head_36_facegen_char = {
    race = ASIAN
    lip_size = { x = 0.7, y = 1.1 }
    nose_base_scale_diff = { x = 0.0, y = 0.25 }
    lip_thickness = { x = 0.6, y = 1.2 }
    chin_face_rot = { x = -0.5, y = 0.0 }
  }
  head_afro_facegen_char = { race = AFRICAN }
}

return {
  EUROPEAN
  ASIAN
  AFRICAN

  genFacesOverrides
}