extends Control
# This script handles dealer-specific behavior in the Blackjack game

# Reference to the game manager (parent)
var game_manager

# Card values and scores
var visible_score = 0
var true_score = 0

func _ready():
	# Get reference to game manager
	game_manager = get_parent()

# Reveal all cards (called when dealer's turn begins)
func reveal_cards():
	for card in $DealerCards.get_children():
		if card.is_face_down:
			card.flip()
	
	# Update visible score to match true score
	update_score()

# Add a card to the dealer's hand
func add_card(card_node):
	$DealerCards.add_child(card_node)
	
	# Update scores
	calculate_score()
	update_score()

# Calculate dealer's score (full score including hidden cards)
func calculate_score():
	var score = 0
	var has_ace = false
	
	for card in $DealerCards.get_children():
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
	
	true_score = score
	return score

# Update the visible score (only counting face-up cards)
func update_score():
	visible_score = 0
	var has_ace = false
	
	for card in $DealerCards.get_children():
		if not card.is_face_down:
			var card_value = card.get_value()
			
			if card_value in ["jack", "queen", "king"]:
				visible_score += 10
			elif card_value == "ace":
				visible_score += 1
				has_ace = true
			else:
				visible_score += int(card_value)
	
	# Handle ace as 11 if it doesn't bust
	if has_ace and visible_score + 10 <= 21:
		visible_score += 10
	
	$DealerScore.text = str(visible_score)

# Check if dealer should hit (standard rule: hit on 16 or less, stand on 17 or more)
func should_hit():
	return calculate_score() < 17

# Dealer takes their turn
func take_turn():
	# First reveal all cards
	reveal_cards()
	
	# Make decisions based on standard dealer rules
	while should_hit():
		# Wait a moment before each hit for visual effect
		await get_tree().create_timer(1.0).timeout
		
		# Request a new card from game manager
		game_manager.deal_card_to_dealer()
	
	# Signal to game manager that dealer's turn is complete
	game_manager.dealer_turn_finished()

# Get the dealer's final score
func get_score():
	return true_score

# Reset dealer for a new game
func reset():
	# Clear all cards
	for card in $DealerCards.get_children():
		card.queue_free()
	
	# Reset scores
	visible_score = 0
	true_score = 0
	$DealerScore.text = "0"
