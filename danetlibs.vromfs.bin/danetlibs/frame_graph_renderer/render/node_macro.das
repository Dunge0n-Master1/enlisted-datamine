module node_macro shared private

require ast
require rtti
require daslib/ast_boost
require daslib/templates_boost

def public move_cls(var target, src)
  unsafe
    target <- src

[structure_macro(name="frame_graph_node")]
class FrameGraphNodeAnnotation : AstStructureAnnotation
  [unused_argument(group)] def override apply(var st : StructurePtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    if args.length != 0
      errors := "expecting [frame_graph_node] to have no arguments"
      return false

    var initfn <- qmacro_function("init`{st.name}") <| $(var x : $t(st)) : void
      move_cls(x, $c(st.name)())
    initfn.flags |= FunctionFlags exports
    add_function(st._module, initfn)

    // add c++ part
    st |> append_annotation("FrameGraph", "_frame_graph_node", [[array< tuple<argname : string; argvalue : RttiValue> >]])

    return true

