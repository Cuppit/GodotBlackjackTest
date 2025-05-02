extends Control
# This script handles player-specific behavior in the Blackjack game

# Reference to the game manager (parent)
var game_manager

# Player state tracking
var score = 0
var has_blackjack = false
var has_bust = false

func _ready():
	# Get reference to game manager
	game_manager = get_parent()

# Add a card to the player's hand
func add_card(card_node):
	$PlayerCards.add_child(card_node)
	
	# Update score
	calculate_score()
	
	# Check for bust
	if score > 21:
		has_bust = true
		game_manager.player_busted()

# Calculate player's score with proper Blackjack rules
func calculate_score():
	score = 0
	var has_ace = false
	
	for card in $PlayerCards.get_children():
		var card_value = card.get_value() # Assuming each card has a get_value method
		
		# Handle face cards
		if card_value in ["jack", "queen", "king"]:
			score += 10
		# Handle ace (initially as 1)
		elif card_value == "ace":
			score += 1
			has_ace = true
		# Handle number cards
		else:
			score += int(card_value)
	
	# Handle ace as 11 if it doesn't bust
	if has_ace and score + 10 <= 21:
		score += 10
	
	# Update score display
	$PlayerScore.text = str(score)
	
	# Check for blackjack (exactly 21 with initial 2 cards)
	if score == 21 and $PlayerCards.get_child_count() == 2:
		has_blackjack = true
	
	return score

# Check if player has 21 (blackjack)
func has_twenty_one():
	return score == 21

# Check if player can double down (only with initial 2 cards)
func can_double_down():
	return $PlayerCards.get_child_count() == 2

# Get the player's current score
func get_score():
	return score

# Get player's blackjack status
func get_has_blackjack():
	return has_blackjack

# Get player's bust status
func get_has_bust():
	return has_bust

# Reset player for a new game
func reset():
	# Clear all cards
	for card in $PlayerCards.get_children():
		card.queue_free()
	
	# Reset states
	score = 0
	has_blackjack = false
	has_bust = false
	$PlayerScore.text = "0"

# Called when player decides to hit
func hit():
	# Request a new card from game manager
	game_manager.deal_card_to_player()

# Called when player decides to stand
func stand():
	# Signal to game manager that player is done
	game_manager.player_stands()

# Called when player decides to double down
func double_down():
	# Signal to game manager for double down
	game_manager.player_doubles_down()
