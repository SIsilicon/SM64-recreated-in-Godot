tool
extends Node

static func approach(value : float, target : float, speed : float) -> float:
	if value < target:
		value += speed
		if value > target:
			value = target
	elif value > target:
		value -= speed
		if value < target:
			value = target
	
	return value

static func approach_signed(value : float, target : float, inc_speed : float, dec_speed : float) -> float:
	if value < target:
		value += inc_speed
		if value > target:
			value = target
	elif value > target:
		value -= dec_speed
		if value < target:
			value = target
	
	return value

static func angle_diff(a1 : float, a2 : float) -> float:
	var diff := wrapf(a1 - a2 + PI, 0, 2*PI) - PI
	return diff + 2*PI if diff < -PI else diff

static func angle_lerp(a1 : float, a2 : float, t : float) -> float:
	var diff := wrapf(a1 - a2 + PI, 0, 2*PI) - PI
	return wrapf(a1 + angle_diff(a2, a1) * t, 0, 2*PI)

static func velocity_from_transforms(trans1 : Transform, trans2 : Transform) -> Vector3:
	var point_a : Vector3 = trans1.xform(Vector3())
	var point_b : Vector3 = trans2.xform(Vector3())
	return point_b - point_a