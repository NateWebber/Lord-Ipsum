extends Control

#TODO: Add score, timer, and area count(?)
func update_hud(health):
	$HealthBar.frame = health
	
func _ready():
	$AnimationPlayer.play("coin")