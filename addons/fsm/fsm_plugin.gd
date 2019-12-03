tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("FSM", "Node", preload("fsm.gd"), preload("icon.png"))
    pass

func _exit_tree():
    remove_custom_type("FSM")
    pass