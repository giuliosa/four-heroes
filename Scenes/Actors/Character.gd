extends KinematicBody2D

const ACCELERATION = 1000
const MAX_SPEED = 150
const FRICTION = 500 

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var fire_rate = 0.4
var can_fire = true

var bullet_scene = preload("res://Scenes/Overlap/Bullet.tscn")

onready var hurtbox = $Hurtbox

func _ready():
	PlayerStats.connect("no_health_player", self, "game_over")

func _process(delta):
	
	#TODO: Remove this, and put in the real world scene
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	$Position2D/Gun.look_at(get_global_mouse_position())
	if (get_global_mouse_position().x < $Position2D.global_position.x):
		$Position2D/Body.flip_h = true
		$Position2D/Gun.flip_v = true
	else:
		$Position2D/Body.flip_h = false
		$Position2D/Gun.flip_v = false
		
	if Input.is_action_pressed("mouse_shoot") and can_fire:
		fire()
		

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)

func move_state(delta):
	#$AnimationPlayer.play("Run")
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	input_vector.y = Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move()

func move():
	velocity = move_and_slide(velocity)


func fire():
	#$AnimationPlayer.play("Shoot")
	var bullet = bullet_scene.instance()
	get_parent().add_child(bullet)
	bullet.global_position = $Position2D/Gun/Position.get_global_position()
	var target = get_global_mouse_position()
	var direction_to_mouse = bullet.global_position.direction_to(target).normalized()
	bullet.direction = direction_to_mouse
	bullet.rotation_degrees = $Position2D/Gun.rotation_degrees
	can_fire = false
	yield(get_tree().create_timer(fire_rate), "timeout")
	can_fire = true
	
func game_over():
	get_tree().change_scene("res://Scenes/Menu/gameover.tscn")

func _on_GunShoot_animation_finished():
	$Position2D/Gun/Position/GunShoot.stop()


func _on_Hurtbox_area_entered(area):
	PlayerStats.health_player -= area.damage
	hurtbox.start_invicibility(0.6)
	hurtbox.create_hit_effect()
