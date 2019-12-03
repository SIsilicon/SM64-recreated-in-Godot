tool
extends Resource
class_name Surface

enum {
	SURFACE_DEFAULT = 0x0000
	SURFACE_HANGABLE = 0x0005
	SURFACE_DEATH_PLANE = 0x000A
	SURFACE_FLOWING_WATER = 0x000E
	SURFACE_WALL_MISC = 0x0028
	SURFACE_VERY_SLIPPERY = 0x0013
	SURFACE_SLIPPERY = 0x0014
	SURFACE_NOT_SLIPPERY = 0x0015
	SURFACE_NOISE_DEFAULT = 0x0029
	SURFACE_NOISE_SLIPPERY = 0x002A
	SURFACE_HARD = 0x0030
	SURFACE_HARD_SLIPPERY = 0x0035
	SURFACE_HARD_VERY_SLIPPERY = 0x0036
	SURFACE_HARD_NOT_SLIPPERY = 0x0037
	SURFACE_NO_CAM_COLLISION = 0x0076
	SURFACE_CAMERA_BOUNDARY = 0x0072
	SURFACE_NOISE_VERY_SLIPPERY = 0x0075
	SURFACE_SWITCH = 0x007A
}

const SURFACE_CLASS_DEFAULT = 0x0000
const SURFACE_CLASS_VERY_SLIPPERY = 0x0013
const SURFACE_CLASS_SLIPPERY = 0x0014
const SURFACE_CLASS_NOT_SLIPPERY = 0x0015

const SURFACE_FLAG_DYNAMIC = 1 << 0
const SURFACE_FLAG_NO_CAM_COLLISION = 1 << 1
const SURFACE_FLAG_X_PROJECTION = 1 << 3

var type : int
var force := 0.0
var collision_object : PhysicsBody

var normal := Vector3()

func _init(normal : Vector3, type : int, object : PhysicsBody):
	self.type = type if typeof(type) == TYPE_INT else SURFACE_DEFAULT
	self.normal = normal
	self.collision_object = object

func is_dynamic() -> bool:
	return bool(collision_object.collision_layer & Collisions.COLLISION_DYNAMIC)

func get_transform_delta(pos : Vector3) -> Vector3:
	if is_dynamic() and collision_object is RigidBody:
		var new_pos = collision_object.global_transform.xform_inv(pos)
		new_pos = new_pos.rotated(Vector3.RIGHT, collision_object.angular_velocity.x)
		new_pos = new_pos.rotated(Vector3.UP, collision_object.angular_velocity.y)
		new_pos = new_pos.rotated(Vector3.FORWARD, collision_object.angular_velocity.z)
		new_pos += collision_object.global_transform.basis.xform_inv(collision_object.linear_velocity * Vector3(1, 0, 1))
		new_pos = collision_object.global_transform.xform(new_pos)
		
		return new_pos - pos
	
	return Vector3()
