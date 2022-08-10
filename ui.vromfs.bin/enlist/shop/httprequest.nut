from "%enlSqGlob/ui_library.nut" import *

let json = require("json")
let http = require("dagor.http")
let userInfo = require("%enlSqGlob/userInfo.nut")

let hasLog = {}
let function logByUrlOnce(url, text) {
  if (url in hasLog)
    return
  hasLog[url] <- true
  log(text)
}

let function requestData(url, params, onSuccess, onFailure=null) {
  http.request({
    method = "POST"
    url = url
    data = params
    callback = function(response) {
      if (response.status != http.SUCCESS || !response?.body) {
        onFailure?()
        return
      }

      try {
        let str = response.body.as_string()
        if (str.len() > 6 && str.slice(0, 6) == "<html>") { //error 404 and other html pages
          logByUrlOnce(url, $"ShopState: Request result is html page instead of data {url}\n{str}")
          onFailure?()
          return
        }
        let data = json.parse(str)
        if (data?.status == "OK")
          onSuccess(data)
        else
          onFailure?()
      }
      catch(e) {
        logByUrlOnce(url, $"ShopState: Request result error {url}")
        onFailure?()
      }
    }
  })
}

let function createGuidsRequestParams(guids) {
  local res = guids.reduce(@(res, guid) $"{res}guids[]={guid}&", "")
  res = $"{res}token={userInfo.value?.token ?? ""}&special=1"
  return res
}

return {
  requestData = requestData
  createGuidsRequestParams = createGuidsRequestParams
}