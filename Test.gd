tool
extends Spatial

var prev_sector : int

func _ready() -> void:
	if Engine.editor_hint:
		for i in range($Surfaces.get_child_count()-1, -1, -1):
			$Surfaces.remove_child($Surfaces.get_child(i))
		
		var collision_data := File.new()
		collision_data.open("res://collision.s", File.READ)
		
		var debug_surf := SurfaceTool.new()
		debug_surf.clear()
		debug_surf.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var vertices := []
		var triangles := PoolVector3Array()
		var surface : StaticBody
		var current_surf_type := -1
		while not collision_data.eof_reached():
			var line := collision_data.get_line()
			
			if line.begins_with("colVertex "):
				line = line.replace("colVertex ", "")
				var coords := line.split_floats(", ", false)
				vertices.append(Vector3(coords[0], coords[1], coords[2]) * Constants.UNIT_SCALE)
			elif line.begins_with("colTriInit "):
				line = line.replace("colTriInit ", "")
				var current_surf_name = line.left(line.find(","))
				
				if surface:
					var shape := ConcavePolygonShape.new()
					shape.set_faces(triangles)
					surface.get_child(0).shape = shape
					triangles.resize(0)
				
				surface = StaticBody.new()
				surface.collision_layer = 0
				surface.name = current_surf_name
				surface.add_child(CollisionShape.new())
				surface.get_child(0).set_deferred("owner", self)
				$Surfaces.add_child(surface)
				surface.owner = self
				
				match line.left(line.find(",")):
					"SURFACE_CAM_NO_COL":
						current_surf_type = Surface.SURFACE_NO_CAM_COLLISION
						surface.collision_layer |= Collisions.COLLISION_STATIC
					"SURFACE_HANGABLE":
						current_surf_type = Surface.SURFACE_HANGABLE
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
					"SURFACE_DEATH_PLANE":
						current_surf_type = Surface.SURFACE_DEATH_PLANE
						surface.collision_layer |= Collisions.COLLISION_STATIC
					"SURFACE_WALL_MISC":
						current_surf_type = Surface.SURFACE_WALL_MISC
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
					"SURFACE_VERY_SLIPPERY":
						current_surf_type = Surface.SURFACE_VERY_SLIPPERY
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
					"SURFACE_SLIPPERY":
						current_surf_type = Surface.SURFACE_SLIPPERY
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
					"SURFACE_NO_SLIPPERY":
						current_surf_type = Surface.SURFACE_NOT_SLIPPERY
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
					_:
						current_surf_type = Surface.SURFACE_DEFAULT
						surface.collision_layer |= Collisions.COLLISION_STATIC | Collisions.COLLISION_CAMERA
				
				surface.set_meta("type", current_surf_type)
	#			print(line.left(line.find(",")))
			
			elif line.begins_with("colTri "):
				line = line.replace("colTri ", "")
				var indices := line.split_floats(", ", false)
				
				debug_surf.add_vertex(vertices[indices[2]])
				debug_surf.add_vertex(vertices[indices[1]])
				debug_surf.add_vertex(vertices[indices[0]])
				
				triangles.append(vertices[indices[2]])
				triangles.append(vertices[indices[1]])
				triangles.append(vertices[indices[0]])
		
		var shape := ConcavePolygonShape.new()
		shape.set_faces(triangles)
		surface.get_child(0).shape = shape
		
		debug_surf.generate_normals()
		debug_surf.index()
		$Debug.mesh = debug_surf.commit()
		
		load_entities_from_file()
	else:
		prev_sector = Global.mario.health >> 8
#		$"Background Music".init_song("Intro")
#		$"Background Music".play("Intro")

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				$Mario.debug_velocity_multiplier += 0.1
			if event.button_index == BUTTON_WHEEL_DOWN:
				$Mario.debug_velocity_multiplier -= 0.1
	
	if event is InputEventKey:
		if event.scancode == KEY_F2 and event.pressed:
			var image := get_tree().get_root().get_texture().get_data()
			image.flip_y()
			
			var time = OS.get_datetime()
			image.save_png("../Screenshot"+str(time.year)+str(time.day)+str(time.hour)+str(time.minute)+str(time.second)+".png")

func _process(delta : float) -> void:
	if not Engine.editor_hint:
		$Debug.translation.x = stepify(Global.mario.translation.x, 655.36)
		$Debug.translation.z = stepify(Global.mario.translation.z, 655.36)
		
		var debug := ""
		debug += "Surface Type: " + (str($Mario.floor_surf.type) if $Mario.floor_surf else "null") + "\n"
		debug += "Surface Height: " + str($Mario.floor_height) + "\n"
		debug += "Mario Pos: " + str($Mario.translation) + "\n"
		debug += "Mario Forward Velocity: " + str($Mario.forward_velocity) + "\n"
		debug += "Mario Face Angle Y: " + str($Mario.face_angle.y) + "\n"
		debug += "Mario Health: " + str($Mario.health) + "\n"
		debug += "Mario Above Slide: " + str($Mario.above_slide) + "\n\n"
		debug += "Mario State Switch per Fram: " + str($Mario.debug_state_switch_count)
		$GUI/Label.text = debug
		
		var sector : int = $Mario.health >> 8
		if sector > 6:
			$GUI/ProgressBar.modulate = Color.blue
		elif sector > 4:
			$GUI/ProgressBar.modulate = Color.green
		elif sector > 2:
			$GUI/ProgressBar.modulate = Color.yellow
		else:
			$GUI/ProgressBar.modulate = Color.red
		$GUI/ProgressBar.value = sector
		
		if sector > prev_sector:
			$GUI/ProgressBar/MeterRefill.play()
			print("refill")
		prev_sector = sector
		
		var coins := float($GUI/VSeparator/CoinCounter.text)
		var prev_coins := coins
		coins = min(coins + 1, Global.coin_counter)
		$GUI/VSeparator/CoinCounter.text = str(coins)
		
		if coins != prev_coins:
			$GUI/VSeparator/CoinSound.translation = Global.mario.translation
			$GUI/VSeparator/CoinSound.play()

func load_entities_from_file():
	# Let's not load anything while we still have entities in the node.
	if $Entities.get_child_count() > 0:
		return
	
	var entity_data := File.new()
	entity_data.open("res://macro.s", File.READ)
	
	while not entity_data.eof_reached():
		var line := entity_data.get_line()
		
		if line.find("macro_object /*preset*/") != -1:
			var char_index := line.find("set*/") + 6
			var char_end := line.find(",")
			var entity := line.substr(char_index, char_end - char_index)
			
			char_index = line.find("pos*/") + 6
			char_end = line.find("/", char_index)
			if char_end == -1:
				char_end = line.length() - 1
			var pos_string := line.substr(char_index, char_end - char_index)
			var pos := pos_string.replace(" ", "").split_floats(",", false)
			
			var entity_node : Spatial
			
			match entity:
				"macro_scuttlebug":
					entity_node = preload("Entities/Scuttlebug/Scuttlebug.tscn").instance()
				"macro_yellow_coin_2":
					entity_node = preload("Entities/Coin/Coin.tscn").instance()
			
			if entity_node:
				# For some reason, the positions in the file don't match up with the level collision.
				# Will have to place adjust positions after loading for now.
				entity_node.translate(Vector3(pos[0], pos[1], pos[2]) * 0.01)
				$Entities.add_child(entity_node)
				entity_node.owner = self
				prints(entity, entity_node.translation)
