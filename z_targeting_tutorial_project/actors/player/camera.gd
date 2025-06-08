extends Node3D


@export var mouse_sensitivity := 0.1



@onready var player := $"../.."
@onready var cam := $SpringArm3D/Camera3D
@onready var spring_arm := $SpringArm3D

var pos_dif : Vector3


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	
	if event is InputEventMouseMotion:
		get_parent().rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))
