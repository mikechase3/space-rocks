extends RigidBody2D

@export var engine_power = 500
@export var spin_power = 8000
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25

enum {INIT, ALIVE, INVULNERABLE, DEAD}
var can_shoot = true
var state = INIT
var thrust = Vector2.ZERO
var rotation_dir = 0
var screensize = Vector2.ZERO  # Book/Slide says Vector.ZERO

var reset_pos = false 
# When value of lives changes, set_lives() will be called -> A "Setter Function"
var lives = 0: set = set_lives # Alllows validation, trigger, protect/private, etc

signal lives_changed
signal dead


func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	
	# Set position back to zero; used with reset()
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false
	
	
func _on_gun_cooldown_timeout() -> void:
	can_shoot = true


func _process(delta):
	get_input()
	#shield += shield_regen * delta

func _ready():
	change_state(ALIVE)
	screensize = get_viewport_rect().size
	$GunCooldown.wait_time = fire_rate
	#print(transform)  # is this a builtin? WOW IT IS!!! 
	


func _physics_process(delta):
	constant_force = thrust
	constant_torque = rotation_dir * spin_power



func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2d.set_deferred("disabled", true)
			#$Sprite2d.modulate.a = 0.5  # Not yet
		ALIVE:
			$CollisionShape2d.set_deferred("disabled", false)
			#$Sprite2d.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2d.set_deferred("disabled", true)
			#$Sprite2d.modulate.a = 0.5
			#$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2d.set_deferred("disabled", true)
			#$Sprite2d.hide()
			#$EngineSound.stop()
			#linear_velocity = Vector2.ZERO
			#dead.emit()
	state = new_state



	
func get_input():
	thrust = Vector2.ZERO  # bug fixed - need it here.
	#$Exhaust.emitting = false
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
		#$Exhaust.emitting = true
		#if not $EngineSound.playing:
			#$EngineSound.play()
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
	else:
		pass
		#$EngineSound.stop()
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	#if Input.is_action_pressed("shoot") and can_shoot:
		#shoot()
		
func reset():
	reset_pos  = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)
		
#func reset():  # called from main
func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)
		
	

		
func shoot():
	if state == INVULNERABLE:
		return
	else:
		can_shoot = false
		$GunCooldown.start()
		var b = bullet_scene.instantiate()  # new bullet to scene
		get_tree().root.add_child(b)  # adds bullet to player's parent, the root.
		b.start($Muzzle.global_transform)  # Passes muzzle's transform.
