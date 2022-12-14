let eventbus = require("eventbus")
let { load_replay_meta_info } = require("app")
let logRP = require("%enlSqGlob/library_logs.nut").with_prefix("[Replay] ")
let {
  REPLAY_DOWNLOAD_PROGRESS,
  REPLAY_DOWNLOAD_FAILED, REPLAY_DOWNLOAD_SUCCESS, replayDownload
} = require("%enlist/replay/replayDownloadState.nut")
let { records, isReplayProtocolValid } = require("%enlist/replay/replaySettings.nut")
let datacache = require("datacache")

eventbus.subscribe("replay.download", function(params) {
  if (replayDownload.value.downloadRequestId != "") // do not download second file
    return

  let { url = null } = params
  if (url == null) {
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/EmptyUrl"
      v.contentLen = -1
    })
    return
  }

  eventbus.subscribe_onehit($"datacache.headers.{url}", function(result) {
    replayDownload.mutate(function (v) {
      v.contentLen = (result?["Content-Length"] ?? -1).tointeger()
    })
  })

  eventbus.subscribe_onehit($"datacache.{url}", function(result) {
    logRP($"Replay '{url}' download result: ", result)
    if (result?.error) {
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = datacache.ERR_MEMORY_LIMIT == result?.error_code ? "replay/memoryLimit" : "replay/HttpError"
        v.downloadRequestId = ""
        v.contentLen = -1
      })
      return
    }

    replayDownload({
      state = REPLAY_DOWNLOAD_SUCCESS
      stateText = "replay/downloadSuccess"
      filename = result.path
      downloadRequestId = ""
      contentLen = -1
    })

    let replayInfo = load_replay_meta_info(result.path)
    if (!replayInfo)
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = "replay/InvalidMeta"
        v.downloadRequestId = ""
        v.contentLen = -1
      })
    else
      records.mutate(@(v) v.append({
        title = result.path.split("/").top()
        id = result.path
        isValid = isReplayProtocolValid(replayInfo)
        recordInfo = replayInfo
      }))
  })
  replayDownload({
    state = REPLAY_DOWNLOAD_PROGRESS
    stateText = ""
    filename = ""
    downloadRequestId = "records"
    contentLen = -1
  })
  datacache.request_entry("records", url)
})
