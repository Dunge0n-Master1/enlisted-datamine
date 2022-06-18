from "%enlSqGlob/ui_library.nut" import *

let function colorize(color, text) {return "<color={0}>{1}</color>".subst(color, text.tostring())}
return colorize