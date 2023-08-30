let { globalWatched } = require("%dngscripts/globalState.nut")
let { editorActivness, editorActivnessUpdate } = globalWatched("editorActivness", @() false)
let { uiInEditor, uiInEditorUpdate } = globalWatched("uiInEditor", @() false)

//dirty hack to hide UI in overlay ui
return {
  editorActivness, editorActivnessUpdate,
  uiInEditor, uiInEditorUpdate
}