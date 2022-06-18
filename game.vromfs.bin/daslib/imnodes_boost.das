options indenting = 4
options no_unused_block_arguments = false
options no_unused_function_arguments = false

module imnodes_boost shared

require imgui public
require imnodes public

require daslib/safe_addr

def BeginNodeEditor ( blk:block )
    BeginNodeEditor()
    invoke(blk)
    EndNodeEditor()

def BeginNode ( id:int; blk:block )
    BeginNode(id)
    invoke(blk)
    EndNode()

def BeginNodeTitleBar ( blk:block )
    BeginNodeTitleBar()
    invoke(blk)
    EndNodeTitleBar()

def BeginInputAttribute ( id:int; shape:ImNodesPinShape; blk:block )
    BeginInputAttribute(id,shape)
    invoke(blk)
    EndInputAttribute()

def BeginInputAttribute ( id:int; blk:block )
    BeginInputAttribute(id,ImNodesPinShape CircleFilled)
    invoke(blk)
    EndInputAttribute()

def BeginOutputAttribute ( id:int; shape:ImNodesPinShape; blk:block )
    BeginOutputAttribute(id,shape)
    invoke(blk)
    EndInputAttribute()

def BeginOutputAttribute ( id:int; blk:block )
    BeginOutputAttribute(id,ImNodesPinShape CircleFilled)
    invoke(blk)
    EndInputAttribute()

def IsLinkCreated( blk:block<(l_from,l_to:int):void> )
    var l_from,l_to:int
    if IsLinkCreated(safe_addr(l_from),safe_addr(l_to))
        invoke(blk,l_from,l_to)

def IsLinkDestroyed( blk:block<(l_id:int):void> )
    var l_id:int
    if IsLinkDestroyed(safe_addr(l_id))
        invoke(blk,l_id)
