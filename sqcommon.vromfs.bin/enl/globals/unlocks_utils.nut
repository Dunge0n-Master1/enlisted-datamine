local function clampStage(unlockDesc, stage) {
  let lastStage = unlockDesc?.stages.len() ?? 0
  if (lastStage > 0 && (unlockDesc?.periodic ?? false)) {
    if (stage >= lastStage) {
      local loopStage = (unlockDesc?.startStageLoop ?? 1) - 1
      if (loopStage >= lastStage)
        loopStage = 0
      stage = loopStage + (stage - loopStage) % (lastStage - loopStage)
    }
  }
  return stage
}

let getStageByIndex = @(unlockDesc, stage) unlockDesc?.stages[clampStage(unlockDesc, stage)]

return {
  clampStage
  getStageByIndex
}