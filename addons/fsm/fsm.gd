extends Node

# Note: a small change was made in this script to better suit this project on line 157

# ShaggyDemiurge Finite State Machine
#
# How it works:
# 1. Add FSM node to scene
# 2. Add nodes (type is irrelevant, simple Node is enough) as children to FSM. Their names (in lowercase) will be
#	state names. States are registered in _on_ready, and changes to list after that aren't reflected in FSM
# 3. Add scripts to nodes (built-in scripts are fine). These scripts should contain methods and parameters with names
#	specified below. All methods are optional
# 4. States could be changed with three different methods (highest to lowest priority, next check happens if previous 
#	fails)
#		* Change state manually (marked M in logs) via fsm.change_state() method. State changed not immediately, but on
#			the next tick of FSM, multiple calls in same tick overwrite each other
#		* Change state from _update() (marked U in logs) - if _update() method returns not-null string, FSM attempts to
#			change state to it
#		* Change state from method checks (marked C in logs). if _check_<next state> method returns true, FSM attempts
#			to change state to it. State priority is determined by node ordering in parent
# 5. State can have methods that are called on entering and leaving it, and also states that are called after change 
#	from and to specific states
#
# For more details look at comments below

export(bool) var running: bool = true							# If false, FSM is inactive, states can't be changed
																#	and update and check methods aren't called
export(bool) var USE_PHYSICS_PROCESS = false					# Specifies if _process or _physics_process should be 
																#	used for _update methods

export(String) var INIT_STATE									# Name of initial state

export(String) var METHOD_INIT = "_state_init"					# Method called once on FSM initialization
export(String) var METHOD_ENTER = "_enter"						# Method called each time this state is entered
export(String) var METHOD_UPDATE = "_update"					# Method called every game tick, takes (delta: float) 
																#	as argument. Can return name of a state that
																#	is supposed to be next
export(String) var METHOD_EXIT = "_exit"						# Method called each time state changes to another one
export(String) var METHOD_PREFIX_CHECK = "_check_"				# If method _check_<state name> returns true, FSM
																#	changes to <state_name>.
																#	Called every tick after update
export(String) var METHOD_PREFIX_TO = "_to_"					# Method _to_<state name> is called when FSM switches 
																#	from this state to <state_name>
																#	Called before _exit()
export(String) var METHOD_PREFIX_FROM = "_from_"				# Method _from_<state name> is called when FSM switches
																#	to this state from <state_name>
																#	Called after _enter()

export(String) var PROPERTY_FSM = "_fsm"						# If state has property with this name, FSM instance is
																# 	injected
export(String) var PROPERTY_ROOT = "_root" 						# If state has property with this name, root node
																#	(specified by ROOT_NODE) is injected
export(NodePath) var ROOT_NODE = NodePath("..")	
export(String) var PROPERTY_PREVIOUS_STATE = "_previous_state"	# If state has property with this name, FSM injects
																# 	name of the previous state

export(bool) var DISCONNECT_INACTIVE_STATES = false				# If true, state node disconnects all incoming signals 
																#	when state becomes inactive
export(bool) var LOG_STATE = false								# If true, logs state changes via print()

const RECURSION_LIMIT = 5
var recursion = 0

var active_state = null

signal state_change(state)

func change_state(new_state_name):
	next_state_manual = new_state_name

func get_node_by_state(state_name):
	return states[state_name].node if states.has(state_name) else null

var state_list = []
var states = {}

var next_state_manual = null

var state_changing_now = false

func _ready():
	print(state_list)
	for child in get_leaf_children(self):
		state_list.append(child.name.to_lower())
	for child in get_leaf_children(self):
		_init_state_from(child)
	for state in states:
		var data = states[state]
		if PROPERTY_FSM in data.node:
			data.node[PROPERTY_FSM] = self
		if PROPERTY_ROOT in data.node:
			data.node[PROPERTY_ROOT] = get_node(ROOT_NODE)
			print (get_node(ROOT_NODE))
		if data.has_init:
			data.node.call(METHOD_INIT)
		_disconnect_state(state)
		
	assert(_check_state_valid(INIT_STATE.to_lower()))
	active_state = INIT_STATE.to_lower()
	var data = states[active_state]
	_connect_state(active_state)
	if data.has_enter:
		data.node.call(METHOD_ENTER)

func _update(delta):
	if !running:
		return
	if state_changing_now:
		return
	if (next_state_manual != null):
		_change_state(next_state_manual, "M")
		return
	var data = states[active_state]
	if data.has_update:
		var next = data.node.call(METHOD_UPDATE, delta)
		if next:
			_change_state(next, "U")
			return
	for state in data.check_states:
		if data.node.call(METHOD_PREFIX_CHECK+state):
			_change_state(state, "C")
			return
	pass

func _change_state(new_state_name, state_change_type):
	assert(_check_state_valid(new_state_name))
	if (state_change_type == null):
		state_change_type = "M"
	
	if new_state_name == active_state:
		if (LOG_STATE):
			if states[active_state].has_prev_state_property:
				states[active_state].node[PROPERTY_PREVIOUS_STATE] = active_state
			print("%s -> %s (%s)" % [new_state_name, new_state_name, state_change_type])
		next_state_manual = null
		return
	
	## Edit: functions names can't have spaces, but the names do.
	## Names will have their spaces replaced with hyphens.
	
	state_changing_now = true
	var from_data = states[active_state]
	var to_data = states[new_state_name]
	if from_data.to_states.has(new_state_name):
		from_data.node.call(METHOD_PREFIX_TO+new_state_name.replace(" ", "_")) # Edited
	if from_data.has_exit:
		from_data.node.call(METHOD_EXIT)
	_disconnect_state(active_state)
	if to_data.has_prev_state_property:
		to_data.node[PROPERTY_PREVIOUS_STATE] = active_state
	_connect_state(new_state_name)
	if to_data.has_enter:
		to_data.node.call(METHOD_ENTER)
	if to_data.from_states.has(active_state):
		to_data.node.call(METHOD_PREFIX_FROM+active_state.replace(" ", "_")) # Edited
	var prev_state = active_state
	active_state = new_state_name
	emit_signal("state_change", new_state_name)
	if (LOG_STATE):
		print("%s -> %s (%s)" % [prev_state, new_state_name, state_change_type])
	state_changing_now = false
	next_state_manual = null
	
	## Edit
	recursion += 1
	if recursion < RECURSION_LIMIT:
		_update(get_physics_process_delta_time() if USE_PHYSICS_PROCESS else get_process_delta_time())
	recursion = 0
	## Edit

# Edit so that it gets updated manually.
#func _process(delta):
#	if !USE_PHYSICS_PROCESS:
#		_update(delta)
#
#func _physics_process(delta):
#	if USE_PHYSICS_PROCESS:
#		_update(delta)

# Edit so that grandchildren nodes are detected as well
func get_leaf_children(node : Node) -> Array:
	var children := []
	for i in node.get_child_count():
		var child := node.get_child(i)
		if child.get_child_count() == 0:
			children.append(child)
		else:
			var grandchildren := get_leaf_children(child)
			for grandchild in grandchildren:
				children.append(grandchild)
	
	return children

func _init_state_from(child):
	var state_name = child.name.to_lower()
	var check_list = []
	var to_list = []
	var from_list = []
	for state in state_list:
		## Edit: Names have spaces which can't be used in functions.
		## Spaces will be replaced with hyphens instead when testing.
		var hyphened_state = state.replace(" ", "_")
		
		if child.has_method(METHOD_PREFIX_CHECK+hyphened_state):
			check_list.append(state)
		if child.has_method(METHOD_PREFIX_TO+hyphened_state):
			to_list.append(state)
		if child.has_method(METHOD_PREFIX_FROM+hyphened_state):
			from_list.append(state)
	var state_data = {
			"node": child,
			"has_init": child.has_method(METHOD_INIT),
			"has_enter": child.has_method(METHOD_ENTER),
			"has_update": child.has_method(METHOD_UPDATE),
			"has_exit": child.has_method(METHOD_EXIT),
			"check_states": check_list,
			"from_states": from_list,
			"to_states": to_list,
			"has_prev_state_property": PROPERTY_PREVIOUS_STATE != "" && PROPERTY_PREVIOUS_STATE in child,
			"signals": null
		}
	#if (LOG_STATE):
	#	print ("State %s \n  %s" % [state_name, state_data])
	states[state_name] = state_data
	
func _connect_state(state_name):
	if (!DISCONNECT_INACTIVE_STATES):
		return
	var data = states[state_name]
	assert(data.signals != null)
	for sig in data.signals:
		var ref = sig.source.get_ref()
		if ref:
			ref.connect(sig.signal_name, data.node, sig.method_name)
	data.signals = null
	pass
	
func _disconnect_state(state_name):
	if (!DISCONNECT_INACTIVE_STATES):
		return
	var data = states[state_name]
	assert(data.signals == null)
	data.signals = data.node.get_incoming_connections()
	for sig in data.signals:
		sig.source.disconnect(sig.signal_name, data.node, sig.method_name)
		sig.source = weakref(sig.source)
	pass
	
func _check_state_valid(state_name):
	if state_list.has(state_name):
		return true
	else:
		printerr("State %s is not found" % state_name)
		return false
