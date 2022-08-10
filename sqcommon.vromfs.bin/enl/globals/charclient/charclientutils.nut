from "%enlSqGlob/ui_library.nut" import *
from "iostream" import blob

/*
Usage:

local t = {
  success = false
  data = {
    start = 10
    count = 1
    mode  = "solo"
    flags = [true, true, false]
  }
}

shortValue(t)        == "{- {1 [+,+,-] solo 10}}"
shortKeyValue(t)     == "{success- data{count:1 flags[+,+,-] mode=solo start:10}}"
shortKeyValue(t, 32) == "{success- data{count:1 flags[+,+*"
*/

//#strict


let function Comma(char = ',') {
  let ch = char
  local i  = 0
  return function(stream) { if (i++ > 0) stream.writen(ch, 'c') }
}


let function dumpValue(value) {
  local lookup
  let stream = blob()

  let function _foreach (val, decor) {
    stream.writen(decor[0], 'c')
    let comma = Comma(decor[1])
    foreach (v in val) {
      comma(stream)
      lookup?[typeof v](v)
    }
    stream.writen(decor[2], 'c')
  }

  lookup = {
    "string"   : @(v) stream.writestring(v)
    "integer"  : @(v) stream.writestring(v.tostring())
    "float"    : @(v) stream.writestring(v.tostring())
    "bool"     : @(v) stream.writestring(v ? "+" : "-")
    "null"     : @(_) stream.writestring("~")
    "array"    : @(v) _foreach (v, "[,]")
    "table"    : @(v) _foreach (v, "{ }")
    "instance" : @(v) _foreach (v, "< >")
  }

  lookup?[typeof value](value)
  return stream
}



let function dumpKeyValue(value) {
  local lookup
  let stream = blob()

  let function _elem(key, separator, str) {
    if (key != "") {
      stream.writestring(key)
      stream.writestring(separator)
    }
    stream.writestring(str)
  }

  let function _foreach (key, val, decor, short=false) {
    stream.writestring(key)
    stream.writen(decor[0], 'c')
    let comma = Comma(decor[1])
    if (short)
      foreach (v in val) {
        comma(stream)
        lookup?[typeof v]("", v)
      }
    else
      foreach (k, v in val) {
        comma(stream)
        lookup?[typeof v](k, v)
      }
    stream.writen(decor[2], 'c')
  }

  lookup = {
    "string"   : @(k, v) _elem(k, "=", v)
    "integer"  : @(k, v) _elem(k, ":", v.tostring())
    "float"    : @(k, v) _elem(k, ":", v.tostring())
    "bool"     : @(k, v) _elem(k, "",  v ? "+" : "-")
    "null"     : @(k, _v) _elem(k, "",  "~")
    "array"    : @(k, v) _foreach (k, v, "[,]", true)
    "table"    : @(k, v) _foreach (k, v, "{ }")
    "instance" : @(k, v) _foreach (k, v, "< >")
  }

  lookup?[typeof value]("", value)
  return stream
}


let function cut(stream, maxLen) {
  if (stream.len() > maxLen) {
    stream.resize(maxLen)
    stream.writestring("*")
  }
  return stream
}


return {
  shortValue    = @(value, maxLen=256) cut(dumpValue(value),    maxLen).tostring()
  shortKeyValue = @(value, maxLen=512) cut(dumpKeyValue(value), maxLen).tostring()
}
