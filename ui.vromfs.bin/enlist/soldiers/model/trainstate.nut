from "%enlSqGlob/ui_library.nut" import *

let { use_soldier_train_order } = require("%enlist/meta/clientApi.nut")

let trainingQueue = Watched({})

let soldierTrainingInProgress = Computed(@() trainingQueue.value.len() > 0)

let function trainSoldier(guid, rankPay, steps) {
  if (guid in trainingQueue.value)
    return

  trainingQueue.mutate(@(train) train[guid] <- true)
  use_soldier_train_order(guid, rankPay, steps, @(_) trainingQueue.mutate(@(v) delete v[guid]))
}

return {
  soldierTrainingInProgress
  trainSoldier
}