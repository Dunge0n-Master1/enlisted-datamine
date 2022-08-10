let eventbus = require("eventbus")
let http = require("dagor.http")
let { load_replay_meta_info } = require("app")
let { file } = require("io")
let { file_exists } = require("dagor.fs")
let { defaultRecordFolder } = require("%enlist/replay/replaySettings.nut")
let logRP = require("%enlSqGlob/library_logs.nut").with_prefix("[Replay] ")
let {
  REPLAY_DOWNLOAD_PROGRESS,
  REPLAY_DOWNLOAD_FAILED, REPLAY_DOWNLOAD_SUCCESS, replayDownload
} = require("%enlist/replay/replayDownloadState.nut")

const EVENT_RECEIVE_REPLAY = "EVENT_RECEIVE_REPLAY"

eventbus.subscribe(EVENT_RECEIVE_REPLAY, function(response) {
  logRP("EVENT_RECEIVE_REPLAY")
  let { status = -1, http_code = 0, body = null, context = null, url = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    logRP($"EVENT_RECEIVE_REPLAY failed: {http_code} {url}")
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/HttpError"
      v.downloadRequestId = 0
    })
    return
  }

  let replayInfo = load_replay_meta_info(context)
  if (!replayInfo) {
    logRP($"Replay meta invalid: {url}")
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/InvalidMeta"
      v.downloadRequestId = 0
    })
    return
  }

  let resultFile = file(context, "wb+")
  resultFile.writeblob(body)
  resultFile.close()
  replayDownload({
    state = REPLAY_DOWNLOAD_SUCCESS
    stateText = "replay/downloadSuccess"
    filename = context
    downloadRequestId = 0
  })
})

let function requestFile(url, filename) {
  return http.request({
    method = "GET"
    url = url
    respEventId = EVENT_RECEIVE_REPLAY
    context = filename
  })
}

eventbus.subscribe("replay.download", function(params) {
  if (replayDownload.value.downloadRequestId != 0) // do not download second file
    return

  let { url = null } = params
  if (url == null) {
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/EmptyUrl"
    })
    return
  }

  let hash = url.replace("/replay.erpl", "").split("/").top()
  let filename = $"{defaultRecordFolder}{hash}.erpl"
  logRP($"Download replay {url} to file {filename}")
  if (file_exists(filename)) {
    if (load_replay_meta_info(filename)) {
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_SUCCESS
        v.stateText = "replay/downloadSuccess"
      })
      return
    }

    logRP($"Replay meta invalid: {filename}")
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/InvalidMeta"
      v.downloadRequestId = 0
    })
    return
  }

  replayDownload({
    state = REPLAY_DOWNLOAD_PROGRESS
    stateText = ""
    filename = filename
    downloadRequestId = requestFile(url, filename)
  })
})
