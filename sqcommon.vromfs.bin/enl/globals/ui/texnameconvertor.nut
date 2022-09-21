let { check_tex_exists } = require("game_load")
let { isHarmonizationEnabled } = require("%enlSqGlob/harmonizationState.nut")

let texNameConvertor = isHarmonizationEnabled.value
  ? function(name) {
      let idx = name.indexof("*")
      if (idx == null)
        return name
      let newName = $"{name.slice(0, idx)}_tomoe*"
      return check_tex_exists(newName) ? newName : name
    }
  : @(name) name

return texNameConvertor