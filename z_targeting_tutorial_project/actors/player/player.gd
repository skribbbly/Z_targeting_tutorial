extends CharacterBody3D


enum{
	FREE,
	TARGET
}


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

var target_tween = Vector2.ZERO

@onready var mesh := $Mesh
@onready var cog := $Mesh/COG
@onready var anim := $AnimationTree

@onready var cam_root := $CamRoot
@onready var spring_arm := $CamRoot/SpringArm3D


var targetable_bodies : Dictionary = {}
var target = null


var target_state : int = FREE


func _ready() -> void:
	
	speed = run_speed
	accel = ground_accel
	resist = ground_resist
	mesh.top_level = true
	cog.top_level = true


func _process(delta: float) -> void:
	
	mesh.global_position = global_position
	
	
	match target_state:
		FREE:
			if direction != Vector3.ZERO:
				mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-direction.x, -direction.z), 10 * delta)
			
			anim.set("parameters/TargBlend/blend_amount", 0)
			
		TARGET:
			mesh.look_at(Vector3(target.target_point.global_position.x,global_position.y,target.target_point.global_position.z))
			cam_root.global_position = (Vector3(global_position.x,global_position.y + 1.1,global_position.z) + target.target_point.global_position) / 2
			spring_arm.spring_length = global_position.distance_to(cam_root.global_position) * 1.7
			
			anim.set("parameters/TargBlend/blend_amount", 1)
			
			var mesh_dir = direction.rotated(Vector3.UP, -mesh.global_transform.basis.get_euler().y).normalized()
			
			var tween = create_tween()
			tween.tween_property(self, "target_tween", Vector2(mesh_dir.x, mesh_dir.z), 0.2)
			
			
			anim.set("parameters/TargetBlendSpace/blend_position", target_tween)
			
			if global_position.distance_to(target.target_point.global_position) > 20:
				end_target()
	# Mesh Rot
	
	#Tilt Stuff
	#var acceleration = (velocity - previous_velocity) / delta
	#var local_accel = cog.global_transform.basis.inverse() * velocity
	#var max_lean_angle = 20.0
	#var lean_strength = 0.5
	#var target_roll  : float = -local_accel.x * (max_lean_angle * clamp(velocity.length() / sprint_speed, 0.0, 1.0))
	#if velocity.length() < 0.5:
		#target_roll = 0
	#var target_rot = cog.rotation_degrees
	#target_rot.z = lerp(target_rot.z, target_roll, 5 * delta)
	#cog.rotation_degrees = target_rot
	

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
	
	
	if Input.is_action_just_pressed("target"):
		if !target:
			var nearest_target = get_nearest_target()
			if nearest_target:
				start_target(nearest_target)
			
		else:
			end_target()
	
	
	anim.set("parameters/RunBlend/blend_amount", clamp(move_vec.length() / speed, 0.0, 1.0))
	
	velocity = move_vec
	
	move_and_slide()
	
	


func get_nearest_target():
	var nearest = null
	var closest_distance = INF
	
	for body in targetable_bodies.values():
		var distance = global_position.distance_to(body.global_position)
		
		if distance < closest_distance:
			closest_distance = distance
			nearest = body
		
	
	return nearest


func start_target(nearest_target) -> void:
	target = nearest_target
	target_state = TARGET


func end_target() -> void:
	target = null
	var tween1 = create_tween()
	var tween2 = create_tween()
	tween1.tween_property(cam_root, "position", Vector3(0, 1.2, 0), 0.6).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(spring_arm, "spring_length", 3, 0.6).set_trans(Tween.TRANS_QUAD)
	target_state = FREE


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Targetable"):
		targetable_bodies[body.get_instance_id()] = body
		
		print("body has entered: " + str(body))


func _on_area_3d_body_exited(body: Node3D) -> void:
	var id = body.get_instance_id()
	if id in targetable_bodies:
		targetable_bodies.erase(id)
		
		print("body has left: " + str(body))
