from "%enlSqGlob/ui_library.nut" import *

let function mkAnimatedEllipsis(fontSize, color, totalnum=3, duration=3.0)  {
  let appearTime = min(duration/(totalnum+1)/5,0.3)
  let function dot(num){
    let hiddenTime = duration/(totalnum+1)*(num+1)
    let showTime = duration-hiddenTime-appearTime
    return {
      rendObj = ROBJ_TEXT
      text = "."
      fontSize = fontSize
      color = color
      key = num
      animations = [
        { prop=AnimProp.opacity, from=0.05, to=0.1, duration=hiddenTime, play=true, trigger="hide", onFinish=$"appear{num}"}
        { prop=AnimProp.opacity, from=0.1, to=1, duration=appearTime, trigger=$"appear{num}", onFinish=$"show{num}"}
        { prop=AnimProp.opacity, from=1, to=1, duration=showTime, trigger=$"show{num}", onFinish=function() {
          if (num==totalnum-1)
            anim_start("hide")
         }
       }
      ]
    }
  }
  let dots = array(totalnum)
  foreach (i, _ in dots)
    dots[i]=dot(i)
  return {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    children = dots
  }
}

local function background_size(parallax = 0, h=sh(100), w=sw(100)){
  if (parallax < 0)
    parallax = -parallax
  h = min(h,w*9.0/16)
  w = max(w,h*16.0/9)
  return [w*(1+parallax*2),h*(1+parallax*2)]
}

let function mkParallaxBkg(imageToShow, parallaxK, height, width){
  let size = background_size(parallaxK, height, width)
  return @(){
    rendObj = ROBJ_IMAGE
    behavior = [Behaviors.Parallax]
    parallaxK = parallaxK
    transform = {pivot = [0,0]}
    keepAspect = KEEP_ASPECT_FILL
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    image = imageToShow.value!=null ? PictureImmediate(imageToShow.value) : null
    watch = [imageToShow]
    size = size
  }
}

return {
  mkAnimatedEllipsis
  mkParallaxBkg
}