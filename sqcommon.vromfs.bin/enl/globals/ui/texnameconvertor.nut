let { get_setting_by_blk_path } = require("settings")
let { check_tex_exists } = require("game_load")

let texNameConvertor = (get_setting_by_blk_path("harmonizationRequired") ?? false)
  ? function(name) {
      let idx = name.indexof("*")
      if (idx == null)
        return name
      let newName = $"{name.slice(0, idx)}_tomoe*"
      return check_tex_exists(newName) ? newName : name
    }
  : @(name) name

return texNameConvertor