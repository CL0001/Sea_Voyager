extends RigidBody3D

@export var max_speed := 5.0
@export var rotation_speed := 1.0
@export var float_force := 5.0
@export var water_drag := 0.05
@export var angular_water_drag := 0.05

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

const water_height := 0.75

var submerged := false

func _process(delta):
	pass

func _physics_process(delta):
	submerged = global_position.y < water_height
	if submerged:
		var depth = water_height - global_position.y
		apply_central_force(Vector3.UP * float_force * gravity * depth)

	if navigation_agent_3d.is_navigation_finished():
		linear_velocity = Vector3.ZERO
		return

	var target_position = navigation_agent_3d.get_next_path_position()
	var direction = global_position.direction_to(target_position)
	
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * rotation_speed)
	
	var velocity = direction * max_speed

	if global_position.distance_to(target_position) < 0.1:
		linear_velocity = Vector3.ZERO
	else:
		linear_velocity = velocity

	# Apply water drag
	if submerged:
		linear_velocity *= (1.0 - water_drag)
		angular_velocity *= (1.0 - angular_water_drag)

func _input(event):
	if Input.is_action_pressed("Mouse_Left"):
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		var mouse_position = get_viewport().get_mouse_position()
		var ray_length = 10000
		
		var from = camera.project_ray_origin(mouse_position)
		var to = from + camera.project_ray_normal(mouse_position) * ray_length
		var space = get_world_3d().direct_space_state
		
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = from
		ray_query.to = to
		ray_query.collide_with_areas = true
		
		var result = space.intersect_ray(ray_query)
		print(result)

		navigation_agent_3d.target_location = result.position

	if event.is_action_pressed("Mouse_Right"): # Clear navigation path
		navigation_agent_3d.stop()
