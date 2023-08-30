from "%enlSqGlob/ui_library.nut" import *


/*
This is a ui manager of ui components that can handle reload of scripts by keeping it in persis table

The idea is to have list of components in a state and a way to add\remove them by some UID
it was implemented differently in code - some implementations consider that component is table and uid can be in it
some consider that component can be found by itself (it doesnt survive reload of scripts)
some use object with uid and component itself and this require to use special methods to get all components and to add\remove them

Here we use the last one, cause it is the only way to handle scripts reload and any component types (functions, tables, classes, null - whatever)
it can even have non darg component in it if is needed for some reason

local l = LayerManager("nameoflayer")
l.add(component, [uid])
l.getComponents() //list of components
l.remove(uid)
l.clear()
l.isInList(uid)

Consider:
  msgboxes should use it too

NOTE:
  we need orderedDictHere in fact. Probably better return it for gerrit to std?
  however. adding and removing windows are rare and amound of windows are also small...
*/

let immutable_types = ["string", "float", "integer"]

//clear unaccasseble widgets on reload

local LayerManager = class{
  name = null
  generation = null
  state = null
  constructor(params){
    assert (immutable_types.indexof(type(params?.name)) != null, @() "'name' param is required fo windowsManager of immutable type (string, float, integer), to allow reload script by persist data, type '{0}' for '{1}'".subst(type(params?.name), params?.name))
    this.name = params.name
    this.generation = Watched(0)
    this.state = []
  }
  function add(component, uid=null){
    if (uid == null)
      uid = component
    let curId = this.state.findindex(@(v) v.uid == uid)
    if (curId == null) {
      this.state.append({component, uid})
    }
    else
      this.state[curId] = {component, uid}
    this.generation(this.generation.value+1)
  }

  function remove(uid){
    let curId = this.state.findindex(@(v) v.uid == uid)
    if (curId != null) {
      this.state.remove(curId)
      this.generation(this.generation.value+1)
    }
  }

  function getComponents(){
    return this.state.map(@(v) v.component)
  }

  function clear(){
    this.state.clear()
    this.generation(this.generation.value+1)
  }

  function getByUid(uid){
    let idx = this.state.findindex(@(v) v.uid == uid)
    return idx == null ? null : this.state[idx]
  }

  function isUidInList(uid){
    return this.state.findindex(@(v) v.uid == uid) != null
  }
}

return LayerManager