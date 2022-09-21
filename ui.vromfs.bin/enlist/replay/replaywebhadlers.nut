let eventbus = require("eventbus")
let { load_replay_meta_info } = require("app")
let logRP = require("%enlSqGlob/library_logs.nut").with_prefix("[Replay] ")
let {
  REPLAY_DOWNLOAD_PROGRESS,
  REPLAY_DOWNLOAD_FAILED, REPLAY_DOWNLOAD_SUCCESS, replayDownload
} = require("%enlist/replay/replayDownloadState.nut")
let datacache = require("datacache")

eventbus.subscribe("replay.download", function(params) {
  if (replayDownload.value.downloadRequestId != "") // do not download second file
    return

  let { url = null } = params
  if (url == null) {
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/EmptyUrl"
    })
    return
  }

  eventbus.subscribe_onehit($"datacache.{url}", function(result) {
    logRP($"Replay '{url}' download result: ", result)
    if (result?.error) {
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = "replay/HttpError"
        v.downloadRequestId = ""
      })
      return
    }

    replayDownload({
      state = REPLAY_DOWNLOAD_SUCCESS
      stateText = "replay/downloadSuccess"
      filename = result.path
      downloadRequestId = ""
    })

    let replayInfo = load_replay_meta_info(result.path)
    if (!replayInfo)
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = "replay/InvalidMeta"
        v.downloadRequestId = ""
      })
  })
  replayDownload({
    state = REPLAY_DOWNLOAD_PROGRESS
    stateText = ""
    filename = ""
    downloadRequestId = "records"
  })
  datacache.request_entry("records", url)
})
