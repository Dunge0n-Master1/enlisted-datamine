from "%enlSqGlob/ui_library.nut" import *

let {chooseRandom} = require("%sqstd/rand.nut")
let {appBgImages} = require("%ui/appBgImages.nut")

const default_bg = "ui/uiskin/grad_vert.png"


local function background_size(parallaxK = 0){
  if (parallaxK < 0)
    parallaxK = -parallaxK
  local h = sh(100)
  local w = sw(100)
  h = max(h,w*9.0/16)
  w = max(w,h*16.0/9)
  return [w*(1+parallaxK),h*(1+parallaxK)]
}

let function background() {
  let parallaxK = -0.02
  let bgImage = (appBgImages.len() == 0) ? default_bg : chooseRandom(appBgImages)
  return{
    rendObj = ROBJ_SOLID
    color = Color(30,30,30)
    size = flex()
    children = [
      {rendObj = ROBJ_IMAGE size = [sw(105),sh(105)] hplace = ALIGN_CENTER valign = ALIGN_CENTER image = PictureImmediate(default_bg) color = Color(40,30,15)}
      {
        size = background_size(parallaxK)
        rendObj = ROBJ_IMAGE
        image = PictureImmediate(bgImage)
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        behavior = [Behaviors.Button,Behaviors.Parallax]
        parallaxK = parallaxK
        transform = {pivot = [0,0]}
        keepAspect=KEEP_ASPECT_FILL //probably we need here another option - image that keep aspects but set size by smaller size
      }
    ]
  }
}

return background