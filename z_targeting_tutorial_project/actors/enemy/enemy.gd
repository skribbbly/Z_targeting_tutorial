extends CharacterBody3D


@onready var target_point := $TargetPoint




func _physics_process(delta: float) -> void:
	
	velocity = Vector3(0, 0, 2) * delta
	
	move_and_slide()
