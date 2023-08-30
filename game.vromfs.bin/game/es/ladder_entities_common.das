module ladder_entities_common shared
require ecs
require DagorMath
require math.base

def make_ladder_tm(height : float; width : float; thickness : float; tm : float3x4)
  let orient = quat(tm)
  var bboxTm = IDENT_TM
  make_tm(orient, bboxTm)
  bboxTm[2] *= width
  bboxTm[1] *= height
  bboxTm[0] *= thickness
  bboxTm[3] = tm[3]
  return bboxTm

