from "%enlSqGlob/ui_library.nut" import *

let function error_response_converter(cb, result) {
  if ("error" in result) {
    cb(result)
    return
  }

  let isSuccess = result?.response?.success ?? true
  if (!isSuccess) {
    cb( { success = false,
          error = result?.response?.error ?? "unknown error" })
    return
  }
  cb(result)
}

return { error_response_converter }
