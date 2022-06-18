let sharedWatched = require("%dngscripts/sharedWatched.nut")
//null or {userId=-1 userIdStr="" name=string or null, token=string or null}

let userInfo = sharedWatched("userInfo", @() null)

return userInfo
