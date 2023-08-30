from "%enlSqGlob/ui_library.nut" import *


let {format} = require("string")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let { secondsToStringLoc, secondsToHoursLoc, locTable } = require("%ui/helpers/time.nut")

let function makeType(id, params) {
  let res = {
    getText = @(value) this.getNotAvailableText(value) ?? this.getTextImpl(value)
    getNotAvailableText = @(value) value == null || value < 0 ? loc("lb/notAvailable") : null
    getTextImpl = @(value) value.tostring()
  }.__update(params)
  res.id <- id
  return res
}

let types = {
  NUM = {
    getTextImpl = @(value) value.tointeger().tostring()
  }

  PERCENT = {
    getTextImpl  = @(value) format("%.1f%%", 100.0 * value)
  }

  PERCENT_FROM_INT = {
    getTextImpl  = @(value) format("%.1f%%", 0.01 * value)
  }

  PLACE = {
    getTextImpl = @(value) (value + 1).tostring()
  }

  NICKNAME = {
    getNotAvailableText = @(value) value ? null : "-"
    getTextImpl = @(value) remap_others(value.tostring())
  }

  RATIO = {
    getTextImpl  = @(value) format("%.2f", value)
  }

  RATIO_FROM_INT = {
    getTextImpl  = @(value) format("%.2f", 0.0001 * value)
  }

  TIME_SEC     = { getTextImpl = secondsToStringLoc }

  TIME_HOURS   = {
    function getTextImpl(v) {
      let res = secondsToHoursLoc(v - (v % 60))
      return res == "" ? $"0{locTable.minutes}" : res
    }
  }

  VICTORY_BOOL = {
    getTextImpl  = @(value) value > 0 ? loc("lb/victory") : loc("lb/defeat")
  }

  RATING_PENALTY = {
    getTextImpl  = @(value) (-1 * value).tostring()
  }
}

foreach (id, t in types)
  types[id] = makeType(id, t)

return types
