extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var disabled = true

var velocity = Vector2()
var jumping = false
var knocked = false
var attacking = false
export var run_speed = 60
export var jump_speed = -200
export var gravity = 600

const UP_DIRECTION = Vector2(0, -1)

onready var explosion = preload("res://scenes/explosion.tscn")

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree


onready var animationState = animationTree.get("parameters/playback")
var dir_last_moved = "Right"

#current health
var health
#max health
var max_health
#current weapon damage
var strength
#knockback power
var player_x_kb = 70
var player_y_kb = 70



# Called when the node enters the scene tree for the first time.
func _ready():
	animationTree.active = true # activate the animation tree
	max_health = 12
	health = 12
	strength = 1
	disabled = false
	visible = true
	attacking=false
	knocked=false

func get_input():
	velocity.x = 0
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var jump = Input.is_action_pressed("ui_up")
	
	if jump and is_on_floor():
		jumping = true
		velocity.y = jump_speed
		get_parent().find_node("Jump").play()
	if right:
		velocity.x += run_speed
	if left:
		velocity.x -= run_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !knocked:
		get_input()
	velocity.y += gravity * delta
	if jumping:
		attacking = false	
	if jumping and is_on_floor():
		jumping = false
	if knocked and is_on_floor():
		knocked = false
	velocity = move_and_slide(velocity, UP_DIRECTION)
	if !attacking:
		get_parent().find_node("AxeSwingSound").stop()
		if(velocity.x > 0):
			animationState.travel("Run Right")
			dir_last_moved = "Right"
		elif(velocity.x < 0):
			animationState.travel("Run Left")
			dir_last_moved = "Left"
		else: # not moving, so just display the idle animation in the direction last moved
			if(dir_last_moved == "Right"):
				animationState.travel("Idle Right")
			elif(dir_last_moved == "Left"):
				animationState.travel("Idle Left")
	if Input.is_action_just_pressed("attack") and !attacking:
		attack()
		#if(dir_last_moved == "Right"):
		#		animationState.travel("Idle Right")
		#elif(dir_last_moved == "Left"):
		#	animationState.travel("Idle Left")

func hit(dmg, x_kb, y_kb, dir):
	attacking = false

	get_parent().find_node("PlayerHurtSound").play()

	velocity.x = 0
	print('Player was hit for ' + str(dmg) + ' damage!')
	health -= dmg
	print('Current health: ' + str(health))
	
	if health < 0:
		health = 0
		
	get_parent().get_node("hud_canvas/HUD").update_hud(health, get_parent().score)
	if health == 0 :
		die()
	else:
		if dir == -1:
			velocity.x -= (run_speed + x_kb)
		else:
			velocity.x += (run_speed + x_kb)
		velocity.y += y_kb
		knocked = true
		velocity = move_and_slide(velocity, UP_DIRECTION)
		$Hitbox/CollisionShape2D.disabled = true
		yield(get_tree().create_timer(5.0), "timeout")
		$Hitbox/CollisionShape2D.disabled = false


	

func attack():
	get_parent().find_node("AxeSwingSound").play()
	attacking = true
	animationState.travel("swing")

func done_attacking():
	attacking = false
	
func die():
	print("Player died!")
	disabled = true
	visible = false
	var boom = explosion.instance()
	boom.position = self.position
	get_parent().add_child(boom)
	get_parent().get_node("bgm").stop()
	yield(get_tree().create_timer(2.0), "timeout")
	get_parent().get_node("hud_canvas/SceneTransitionRect").transition_to("res://scenes/menus/gameover.tscn")
	
	
func _on_SwordBox_area_entered(area):
	if area.is_in_group("enemies"):
		area.get_parent().hit()
