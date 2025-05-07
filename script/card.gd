extends Control

# Card properties
var suit = ""
var value = ""
var is_face_down = false

# Animation references
@onready var card_front = $CardFront
@onready var card_back = $CardBack
@onready var flip_animation = $FlipAnimation

# Called when the node enters the scene tree for the first time
func _ready():
	# Create animations if they don't exist
	if not flip_animation.has_animation("flip_to_front"):
		create_flip_animations()
	
	# Set initial visibility based on face_down state
	update_visibility()

# Initialize the card with suit and value
func initialize(card_suit, card_value, face_down = false):
	suit = card_suit
	value = card_value
	is_face_down = face_down
	
	# Load the appropriate texture for the card front
	var card_texture = load("res://assets/images/cards/" + suit + "_" + value + ".png")
	if card_texture:
		card_front.texture = card_texture
	
	# Set initial state
	update_visibility()

# Creates flip animations programmatically
func create_flip_animations():
	# Create a new animation for flipping to front
	
	# add_animation 
	return null
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:scale")
	animation.track_insert_key(track_idx, 0.0, Vector2(1, 1))
	animation.track_insert_key(track_idx, 0.15, Vector2(0.1, 1))
	animation.track_insert_key(track_idx, 0.3, Vector2(1, 1))
	
	# Add track for visibility changes
	track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "CardFront:visible")
	animation.track_insert_key(track_idx, 0.0, false)
	animation.track_insert_key(track_idx, 0.15, true)
	
	track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "CardBack:visible")
	animation.track_insert_key(track_idx, 0.0, true)
	animation.track_insert_key(track_idx, 0.15, false)
	
	animation.length = 0.3
	flip_animation.add_animation("flip_to_front", animation)
	
	# Create animation for flipping to back (reverse of flip_to_front)
	animation = Animation.new()
	track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:scale")
	animation.track_insert_key(track_idx, 0.0, Vector2(1, 1))
	animation.track_insert_key(track_idx, 0.15, Vector2(0.1, 1))
	animation.track_insert_key(track_idx, 0.3, Vector2(1, 1))
	
	track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "CardFront:visible")
	animation.track_insert_key(track_idx, 0.0, true)
	animation.track_insert_key(track_idx, 0.15, false)
	
	track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "CardBack:visible")
	animation.track_insert_key(track_idx, 0.0, false)
	animation.track_insert_key(track_idx, 0.15, true)
	
	animation.length = 0.3
	flip_animation.add_animation("flip_to_back", animation)

# Update card visibility based on face-up/down state
func update_visibility():
	card_front.visible = !is_face_down
	card_back.visible = is_face_down

# Flip the card
func flip():
	is_face_down = !is_face_down
	
	# Play the appropriate animation
	if is_face_down:
		flip_animation.play("flip_to_back")
	else:
		flip_animation.play("flip_to_front")

# Get the card's value
func get_value():
	return value

# Get the card's suit
func get_suit():
	return suit

# Get numeric value for scoring
func get_numeric_value():
	if value in ["jack", "queen", "king"]:
		return 10
	elif value == "ace":
		return 1  # Ace is handled specially by the scoring system
	else:
		return int(value)
