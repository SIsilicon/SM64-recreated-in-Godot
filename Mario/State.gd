extends Node
class_name State

const ACT_FLAG_STATIONARY                 = 0x00000200
const ACT_FLAG_MOVING                     = 0x00000400
const ACT_FLAG_AIR                        = 0x00000800
const ACT_FLAG_INTANGIBLE                 = 0x00001000
const ACT_FLAG_SWIMMING                   = 0x00002000
const ACT_FLAG_METAL_WATER                = 0x00004000
const ACT_FLAG_SHORT_HITBOX               = 0x00008000
const ACT_FLAG_RIDING_SHELL               = 0x00010000
const ACT_FLAG_INVULNERABLE               = 0x00020000
const ACT_FLAG_BUTT_OR_STOMACH_SLIDE      = 0x00040000
const ACT_FLAG_DIVING                     = 0x00080000
const ACT_FLAG_ON_POLE                    = 0x00100000
const ACT_FLAG_HANGING                    = 0x00200000
const ACT_FLAG_IDLE                       = 0x00400000
const ACT_FLAG_ATTACKING                  = 0x00800000
const ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION = 0x01000000
const ACT_FLAG_CONTROL_JUMP_HEIGHT        = 0x02000000
const ACT_FLAG_ALLOW_FIRST_PERSON         = 0x04000000
const ACT_FLAG_PAUSE_EXIT                 = 0x08000000


var action_timer : int

var _fsm
var _mario : Mario

func get_flags() -> int:
	return -1