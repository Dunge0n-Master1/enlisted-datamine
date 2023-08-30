from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {platformId} = require("%dngscripts/platform.nut")
let {circuit, version} = require("%dngscripts/appInfo.nut")
let { getLanguageId } = require("%enlSqGlob/httpPkg.nut")

local bugReportUrl = get_setting_by_blk_path("communityBugTrackerURL")
if (bugReportUrl!=null)
  bugReportUrl = $"{bugReportUrl}?f.platform={platformId}&f.version={version.value}&f.circuit={circuit.value}"
else
  bugReportUrl=""

return {
  gaijinSupportUrl = get_setting_by_blk_path("gaijinSupportUrl") ?? "https://support.gaijin.net/"
  enlistedForumUrl = get_setting_by_blk_path("enlistedForumUrl") ?? "https://forum.enlisted.net/auth/gaijin/callback"
  feedbackUrl      = get_setting_by_blk_path("feedbackUrl") ?? ""
  bugReportUrl
  legalsUrl = $"https://legal.gaijin.net/{getLanguageId()}"
}

