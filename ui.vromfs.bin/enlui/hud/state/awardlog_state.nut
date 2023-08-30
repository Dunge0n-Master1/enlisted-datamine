
let EventLogState = require("%ui/hud/state/eventlog_state.nut")
let {get_sync_time} = require("net")

let AwardLogState = class extends EventLogState {
  unAwardedScore = {}
  unAwardedScoreLastInsertTime = 0
  unAwardedScoreKeepTime = 5

  function tryAddCachedScoreToAward(awardData) {
    let scoreId = awardData?.scoreId
    if (scoreId) {
      let score = this.unAwardedScore?[scoreId]
      if (score) {
        delete this.unAwardedScore[scoreId]
        awardData.score <- (awardData?.score ?? 0) + score
      }
    }
  }

  function cacheUnawardedScore(awardData) {
    let score = awardData?.score ?? 0
    let scoreId = awardData?.type ?? ""
    if (score > 0 && scoreId != "") {
      this.unAwardedScore[scoreId] <- (this.unAwardedScore?[scoreId] ?? 0) + score
      this.unAwardedScoreLastInsertTime = get_sync_time()
    }
  }

  function tryApplyScore(awardData) {
    let scoreId = awardData?.type
    let score = awardData.score
    local isApplied = false
    if (scoreId) {
      this.events.mutate(function(eventsVal) {
        foreach (e in eventsVal)
          if (e?.awardData.scoreId == scoreId) {
            e.awardData.score <- (e.awardData?.score ?? 0) + score
            isApplied = true
            break
          }
      })
    }
    return isApplied
  }

  function checkClearUnAwardedCache() {
    if (this.events.value.len() == 0
      && get_sync_time() - this.unAwardedScoreLastInsertTime > this.unAwardedScoreKeepTime) {
        this.unAwardedScore.clear()
    }
  }

  function awardGroupKey(award) {
    return award?.awardData.groupKey ?? award?.awardData.type
  }

  function isEventSame(a, b) {
    return this.awardGroupKey(a) == this.awardGroupKey(b)
  }

  function groupSame(event) {
    for (local i = this.events.value.len() - 1; i >= 0; i--) {
      let eventToRemove = this.events.value[i]
      if (this.isEventSame(eventToRemove, event)) {
        event.num <- (eventToRemove?.num ?? 1) + 1
        this.events.value.remove(i)
        break
      }
    }
  }

  function pushEvent(eventExt, collapseBy=null) {
    this.checkClearUnAwardedCache()
    let awardData = eventExt?.awardData
    this.tryAddCachedScoreToAward(awardData)
    if (!(awardData?.hasAward ?? true)) {
      if (!this.tryApplyScore(awardData))
        this.cacheUnawardedScore(awardData)
      return
    }
    this.groupSame(eventExt)
    base.pushEvent(eventExt, collapseBy)
  }
}

return AwardLogState
