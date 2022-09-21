let {globalWatched} = require("%dngscripts/globalState.nut")

let {userInfo, userInfoUpdate} = globalWatched("userInfo")

return {userInfo, userInfoUpdate}
