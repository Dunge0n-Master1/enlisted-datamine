let {isEqual} = require("%sqstd/underscore.nut")
let DataBlock = require("DataBlock") //for debug purposes
let {TMatrix, Point2, Point3, Point4, Color3, Color4, IPoint2, IPoint3} = require("dagor.math")
let logLib = require("%sqstd/log.nut")
let {tostring_r} = require("%sqstd/string.nut")
let {Watched} = require("frp")
let console = require_optional("console")

const BLK_MAX_DEEP_LEVEL = 5
const BLK_MAX_LINES = 2048
let tostringfuncTbl = [
  {
    compare = @(val) val instanceof Watched
    tostring = @(val) "Watched: {0}".subst(tostring_r(val.value,{maxdeeplevel = 3, splitlines=false}))
  }
  {
    compare = @(val) type(val)=="instance" && "formatAsString" in val
    tostring = @(val) val.formatAsString({init_indent=0, max_level_depth=BLK_MAX_DEEP_LEVEL, max_out_line_num=BLK_MAX_LINES})
    // to make correct format to string we need implement iterator of tostring in blk. Too much work.
    // Or we need to rewrite current to string to accept inital indent and max recursion level. That is possible but also not fast
  }
]
let customIsEqual = {}
let specifiedIsEqual = @(val1, val2, customIsEqualTbl = customIsEqual) isEqual(val1, val2, customIsEqualTbl)

customIsEqual.__update({
  [DataBlock] = function(val1, val2) {
    if (val1.paramCount() != val2.paramCount() || val1.blockCount() != val2.blockCount())
      return false

    for (local i = 0; i < val1.paramCount(); i++)
      if (val1.getParamName(i) != val2.getParamName(i) || ! isEqual(val1.getParamValue(i), val2.getParamValue(i)))
        return false
    for (local i = 0; i < val1.blockCount(); i++) {
      let b1 = val1.getBlock(i)
      let b2 = val2.getBlock(i)
      if (b1.getBlockName() != b2.getBlockName() || !specifiedIsEqual(b1, b2))
        return false
    }
    return true
  },
  [IPoint2] = @(val1, val2) val1.x == val2.x && val1.y == val2.y,
  [IPoint3] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z,
  [Point2] = @(val1, val2) val1.x == val2.x && val1.y == val2.y,
  [Point3] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z,
  [Point4] = @(val1, val2) val1.x == val2.x && val1.y == val2.y && val1.z == val2.z && val1.w == val2.w,
  [Color4] = @(val1, val2) val1.r == val2.r && val1.g == val2.g && val1.b == val2.b && val1.a == val2.a,
  [Color3] = @(val1, val2) val1.r == val2.r && val1.g == val2.g && val1.b == val2.b,
  [TMatrix] = function(val1, val2) {
    for (local i = 0; i < 4; i++)
      if (!isEqual(val1[i], val2[i]))
        return false
    return true
  }
})

let log = logLib(tostringfuncTbl)

console?.setObjPrintFunc(log.debugTableData)

let export = {
  isEqual = specifiedIsEqual
  log_for_user = log.dlog //warning disable: -dlog-warn
  dlog = log.dlog //warning disable: -dlog-warn
  log = log.log
  dlogsplit = log.dlogsplit
  vlog = log.vlog
  console_print = log.console_print
  wlog = log.wlog
  with_prefix = log.with_prefix
  wdlog = @(watched, prefix = null, transform=null) log.wlog(watched, prefix, transform, log.dlog) //disable: -dlog-warn
  debugTableData = log.debugTableData
}

return export
