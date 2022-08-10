from "%enlSqGlob/ui_library.nut" import *

let hudLayoutStateGen = Watched(0)
let he = {
  leftPanelTop = []
  leftPanelMiddle = []
  leftPanelBottom = []
  centerPanelTop = []
  centerPanelMiddle = []
  centerPanelBottom = []
  rightPanelTop = []
  rightPanelMiddle = []
  rightPanelBottom = []
}

let hudState = {
  hudLayoutStateGen
  addToPanel = function(panel, elems) {
    foreach (elem in elems) {
      let pos = elem?.pos
      panel.insert(min(pos ?? panel.len(), panel.len()), pos == null ? elem : elem.value)
    }
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getLeftPanelTop = @() he.leftPanelTop
  leftPanelTop = function(elems) {
    he.leftPanelTop = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getLeftPanelMiddle = @() he.leftPanelMiddle
  leftPanelMiddle = function(elems) {
    he.leftPanelMiddle = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getLeftPanelBottom = @() he.leftPanelBottom
  leftPanelBottom = function(elems) {
    he.leftPanelBottom = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getCenterPanelTop = @() he.centerPanelTop
  centerPanelTop    = function(elems) {
    he.centerPanelTop = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getCenterPanelMiddle = @() he.centerPanelMiddle
  centerPanelMiddle = function(elems) {
    he.centerPanelMiddle = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getCenterPanelBottom = @() he.centerPanelBottom
  centerPanelBottom = function(elems) {
    he.centerPanelBottom = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getRightPanelTop = @() he.rightPanelTop
  rightPanelTop    = function(elems) {
    he.rightPanelTop = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getRightPanelMiddle = @() he.rightPanelMiddle
  rightPanelMiddle = function(elems) {
    he.rightPanelMiddle = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }
  getRightPanelBottom = @() he.rightPanelBottom
  rightPanelBottom = function(elems) {
    he.rightPanelBottom = elems
    hudLayoutStateGen(hudLayoutStateGen.value+1)
  }

  debug_borders = mkWatched(persist, "debug_borders", false)

  centerPanelBottomStyle = Watched({})
  centerPanelTopStyle = Watched({})
  centerPanelMiddleStyle = Watched({})

  rightPanelBottomStyle = Watched({})
  rightPanelTopStyle = Watched({})
  rightPanelMiddleStyle = Watched({})

  leftPanelBottomStyle = Watched({})
  leftPanelTopStyle = Watched({})
  leftPanelMiddleStyle = Watched({})
}

console_register_command(@() hudState.debug_borders.update(!hudState.debug_borders.value),"ui.hud_layout_borders_debug")

return hudState
