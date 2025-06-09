extends CharacterBody3D


var speed : float

@export var walk_speed : float = 2
@export var run_speed : float = 5
@export var sprint_speed : float = 11


var accel : float
@export var ground_accel : float = 30


var resist : float
@export var ground_resist : float = 30


var direction : Vector3
var move_vec : Vector3
var gravity_vec : Vector3

var previous_velocity: Vector3 = Vector3.ZERO
var previous_pos : Vector3


@onready var mesh := $Mesh
@onready var cog := $Mesh/COG
@onready var anim := $AnimationTree


func _ready() -> void:
	
	speed = run_speed
	accel = ground_accel
	resist = ground_resist
	mesh.top_level = true
	cog.top_level = true


func _process(delta: float) -> void:
	mesh.global_position = global_position
	cog.global_position = global_position + Vector3(0, 0.9, 0)
	if direction != Vector3.ZERO:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-direction.x, -direction.z), 10 * delta)
		cog.rotation.y = mesh.rotation.y
	var acceleration = (velocity - previous_velocity) / delta
	#previous_velocity = velocity

	var local_accel = cog.global_transform.basis.inverse() * velocity

	var max_lean_angle = 40.0
	var lean_strength = 0.5

	var target_pitch : float = -max_lean_angle * clamp(velocity.length() / sprint_speed, 0.0, 1.0)
	var target_roll  : float = -local_accel.x * (max_lean_angle * clamp(velocity.length() / sprint_speed, 0.0, 1.0))

	if velocity.length() < 0.5:
		target_pitch = 0
		target_roll = 0

	var target_rot = cog.rotation_degrees
	target_rot.x = lerp(target_rot.x, target_pitch, 5 * delta)
	target_rot.z = lerp(target_rot.z, target_roll, 5 * delta)

	cog.rotation_degrees = target_rot


func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	
	var h_rot = global_transform.basis.get_euler().y
	
	var input_vec = Vector2.ZERO
	
	input_vec.x -= Input.get_action_strength("left") - Input.get_action_strength("right")
	input_vec.y -= Input.get_action_strength("up") - Input.get_action_strength("down")
	
	direction = Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, h_rot).normalized()
	
	if input_vec != Vector2.ZERO:
		move_vec = move_vec.move_toward(direction * speed, accel * delta)
	else:
		move_vec = move_vec.move_toward(Vector3.ZERO, resist * delta)
	
	
	previous_pos = position
	
	velocity = move_vec
	
	move_and_slide()
	
	process_animation()
	
	var angular_velocity = velocity.length() / $Mesh/CSGCylinder3D.radius
	var rotation_axis = velocity.normalized().cross(Vector3.UP)  # axis perpendicular to movement
	
	var rotation_amount = angular_velocity * delta
	$Mesh/CSGCylinder3D.rotate_x(-rotation_amount)


func process_animation():
	
	if velocity != Vector3.ZERO:
		
		
		if $Mesh/CSGCylinder3D/RayCast3D.is_colliding():
			anim.set("parameters/Run/transition_request", "Run_01")
			
		if $Mesh/CSGCylinder3D/RayCast3D2.is_colliding():
			anim.set("parameters/Run/transition_request", "Run_02")
			
		if $Mesh/CSGCylinder3D/RayCast3D3.is_colliding():
			anim.set("parameters/Run/transition_request", "Run_03")
			
		
		if $Mesh/CSGCylinder3D/RayCast3D4.is_colliding():
			anim.set("parameters/Run/transition_request", "Run_04")
