import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let loadingImages = Watched()

ecs.register_es("loading_images_ui_es",{
    function onInit(_eid, comp){
      let images = comp.loading_images?.getAll()
      loadingImages((images?.len() ?? 0) > 0 ? images : null)
    }
    function onDestroy(_eid, _comp){
      loadingImages(null)
    }
  },
  {comps_ro = [["loading_images", ecs.TYPE_STRING_LIST]]}
)

return {loadingImages}