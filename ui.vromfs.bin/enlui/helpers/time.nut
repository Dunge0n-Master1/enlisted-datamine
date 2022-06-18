from "%enlSqGlob/ui_library.nut" import *

let {format} = require("string")
let timeBase = require("%sqstd/time.nut")
let {secondsToTimeFormatString, roundTime, secondsToTime} = timeBase

let locTable ={
  seconds =loc("measureUnits/seconds"),
  days =loc("measureUnits/days"),
  minutes =loc("measureUnits/minutes")
  hours =loc("measureUnits/hours")
}

let locFullTable ={
  seconds =loc("measureUnits/seconds"),
  days =loc("measureUnits/full/days"),
  minutes =loc("measureUnits/full/minutes")
  hours =loc("measureUnits/full/hours")
}

let secondsToStringLoc = @(time) secondsToTimeFormatString(time).subst(locTable)

let secondsToHoursLoc = @(time) secondsToTimeFormatString(roundTime(time)).subst(locTable)

let function secondsToTimeFormatStringWithSec(time) {
  let {days=0, hours=0, minutes=0, seconds=0} = secondsToTime(time)
  let res = []
  if (days>0)
    res.append("{0}{days}".subst(days))
  if (hours>0)
    res.append("{0}{hours}".subst(hours))
  if (minutes>0 || days > 0 )
    res.append("{0}{minutes}".subst(minutes))
  res.append("{0}{seconds}".subst(minutes+hours > 0 ? format("%02d", seconds) : seconds.tostring()))
  return " ".join(res)
}

let secondsToHoursLocFull = @(time) secondsToTimeFormatString(roundTime(time)).subst(locFullTable)
let secondsToString = timeBase.secondsToTimeSimpleString

return timeBase.__merge({
  secondsToString
  secondsToTimeFormatStringWithSec
  secondsToStringLoc
  secondsToHoursLoc
  secondsToHoursLocFull
  locTable
  locFullTable
})