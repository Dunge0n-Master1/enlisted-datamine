from "%enlSqGlob/ui_library.nut" import *

let { Point2 } = require("dagor.math")

const DIST_INC_TIER = 0.15
const DIST_INC_LINE = 0.0
const OFFS_TIER = 0.4
const OFFS_LINE = 0.4

let midVal = @(tierVal, lineVal, tier, line)
  (tierVal * tier + lineVal * line) / (tier + line)

let function getOffsets(total, tierDiff, lineDiff) {
  let center = Point2(tierDiff.tofloat(), lineDiff.tofloat())
  let dist = center.length()
  if (dist == 0)
    return array(total, Point2(0, 0))

  let step = Point2(midVal(0, OFFS_LINE, tierDiff, lineDiff),
                      midVal(OFFS_TIER, 0, tierDiff, lineDiff))
  let newDist = dist + midVal(DIST_INC_TIER, DIST_INC_LINE, tierDiff, lineDiff)
  let start = center * (newDist / dist) - step * (0.5 * (total - 1))
  return array(total).map(function(_, idx) {
    let newPos = start + step * idx
    newPos.normalize()
    return newPos * newDist - center
  })
}

let function recalcMultiResearchPos(pageResearches) {
  let groups = {}
  foreach (res in pageResearches) {
    let { multiresearchGroup = 0 } = res
    if (multiresearchGroup > 0) {
      if (multiresearchGroup not in groups)
        groups[multiresearchGroup] <- []
      groups[multiresearchGroup].append(res)
    }
  }

  foreach (g in groups) {
    let { tier, line, requirements } = g[0]
    let reqResearchId = requirements?[0]
    //recalc pos only when same position, and requirement
    if (g.len() == 1) {
      pageResearches[g[0].research_id] <- g[0].__merge({ multiresearchGroup = 0 }) //when only single item should to view it as not groupped
      continue
    }

    let group = g.filter(@(r) r.tier == tier && r.line == line && r.requirements?[0] == reqResearchId)
    if (group.len() <= 1)
      continue
    group.sort(@(a, b) a.research_id <=> b.research_id)

    let reqResearch = pageResearches?[reqResearchId]
    let reqTier = reqResearch?.tier ?? tier
    let reqLine = reqResearch?.line ?? (line - 1)

    let offsets = getOffsets(group.len(), tier - reqTier, line - reqLine)
    foreach (idx, offs in offsets)
      pageResearches[group[idx].research_id] <- group[idx].__merge({ tier = tier + offs.x, line = line + offs.y })
  }
}

return recalcMultiResearchPos