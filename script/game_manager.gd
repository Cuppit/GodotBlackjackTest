extends Control

# Game state enum
enum GameState {BETTING, PLAYER_TURN, DEALER_TURN, GAME_OVER}
var current_state = GameState.BETTING

# Game variables
var player_money = 1000
var current_bet = 0
var deck = []
var is_dealing = false

# References to key nodes
@onready var dealer_cards = $DealerArea/DealerCards
@onready var player_cards = $PlayerArea/PlayerCards
@onready var dealer_score_label = $DealerArea/DealerScore
@onready var player_score_label = $PlayerArea/PlayerScore
@onready var bet_label = $BettingArea/BetAmount
@onready var money_label = $PlayerInfo/MoneyLabel
@onready var game_message = $UI/GameMessage
@onready var hit_button = $GameControls/HitButton
@onready var stand_button = $GameControls/StandButton
@onready var double_button = $GameControls/DoubleButton
@onready var deal_button = $GameControls/DealButton
@onready var sound_fx = $SoundFX

# Card scene reference - you'll need to create this
var card_scene = preload("res://scenes/card.tscn")

func _ready():
	# Initialize the game
	money_label.text = "$" + str(player_money)
	init_game()

func _process(_delta):
	update_ui_info()

func init_game():
	# Reset the game state
	clear_cards()
	current_state = GameState.BETTING
	current_bet = 0
	bet_label.text = "BET: $0"
	game_message.text = ""
	
	# Set button states
	deal_button.disabled = true
	hit_button.disabled = true
	stand_button.disabled = true
	double_button.disabled = true
	
	# Create and shuffle the deck
	create_deck()

func create_deck():
	deck = []
	var suits = ["hearts", "diamonds", "clubs", "spades"]
	var values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
	
	for suit in suits:
		for value in values:
			deck.append({"suit": suit, "value": value})
	
	# Shuffle the deck
	deck.shuffle()

func clear_cards():
	# Remove all cards from player and dealer areas
	for child in player_cards.get_children():
		child.queue_free()
	
	for child in dealer_cards.get_children():
		child.queue_free()
	
	player_score_label.text = "0"
	dealer_score_label.text = "0"

func deal_initial_cards():
	# Deal 2 cards to player and dealer
	deal_card(player_cards, false)
	deal_card(dealer_cards, false)  # First dealer card is face down
	deal_card(player_cards, false)
	deal_card(dealer_cards, false)
	
	# Update scores
	update_score(player_cards, player_score_label)
	update_dealer_score()
	
	# Check for blackjack
	check_for_blackjack()

func deal_card_to_dealer():
	deal_card(dealer_cards, false)

func deal_card_to_player():
	deal_card(player_cards, false)
	

func deal_card(target, face_down = false):
	if deck.size() == 0:
		print("Deck is empty!")
		return
	
	var card_data = deck.pop_front()
	var new_card = card_scene.instantiate()
	#add_child(new_card)
	# Set card data and face-up/down state
	target.add_child(new_card)
	new_card.initialize(card_data.suit, card_data.value, face_down)
	
	
	# Play sound effect
	play_sound("card_deal")

# Updates info labels with latest info
func update_ui_info():
	$PlayerInfo/MoneyLabel.text = "$"+str(player_money)
	$BettingArea/BetAmount.text = "$"+str(current_bet)
	$PlayerArea/PlayerScore.text = "HAND VALUE: "+str(calculate_score(player_cards))
	$DealerArea/DealerScore.text=  "HAND VALUE: "+str(calculate_score(dealer_cards))
	
	# Check which buttons are available
	if (current_state == GameState.BETTING) && (current_bet > 0):
		$GameControls/DealButton.disabled = false

func increase_bet(amount):
	if player_money >= amount:
		player_money -= amount
		current_bet += amount

func update_score(cards_container, score_label):
	var score = calculate_score(cards_container)
	score_label.text = str(score)

func update_dealer_score():
	# Only count visible cards for dealer's displayed score
	var visible_score = 0
	var cards = dealer_cards.get_children()
	
	for card in cards:
		if not card.is_face_down:
			visible_score += get_card_value(card.value)
	
	dealer_score_label.text = str(visible_score)

func calculate_score(cards_container):
	var score = 0
	var has_ace = false
	var cards = cards_container.get_children()
	
	for card in cards:
		if not card.is_face_down:
			var value = get_card_value(card.value)
			score += value
			
			if card.value == "ace":
				has_ace = true
	
	# Handle ace as 1 or 11
	if has_ace and score + 10 <= 21:
		score += 10
		
	return score

func get_card_value(value):
	if value in ["jack", "queen", "king"]:
		return 10
	elif value == "ace":
		return 1  # Ace is initially 1, can be 11 later
	else:
		return int(value)

func check_for_blackjack():
	var player_score = int(player_score_label.text)
	
	if player_score == 21:
		# Reveal dealer's hidden card
		reveal_dealer_cards()
		var dealer_score = calculate_score(dealer_cards)
		
		if dealer_score == 21:
			# Both have blackjack - push
			end_game("PUSH - Both have Blackjack")
		else:
			# Player has blackjack - pay 3:2
			var winnings = int(current_bet * 1.5)
			player_money += current_bet + winnings
			money_label.text = "$" + str(player_money)
			end_game("BLACKJACK! You win $" + str(winnings))
	else:
		# Continue with player's turn
		current_state = GameState.PLAYER_TURN
		hit_button.disabled = false
		stand_button.disabled = false
		double_button.disabled = false

func reveal_dealer_cards():
	for card in dealer_cards.get_children():
		if card.is_face_down:
			card.flip()
	
	update_score(dealer_cards, dealer_score_label)

func player_hit():
	deal_card(player_cards, false)
	update_score(player_cards, player_score_label)
	
	# Disable double after hitting
	double_button.disabled = true
	
	# Check if player busts
	var player_score = int(player_score_label.text)
	if player_score > 21:
		player_bust()

func player_stand():
	current_state = GameState.DEALER_TURN
	hit_button.disabled = true
	stand_button.disabled = true
	double_button.disabled = true
	
	# Reveal dealer's hidden card
	reveal_dealer_cards()
	
	# Dealer's turn
	dealer_turn()

func player_double():
	# Double the bet
	player_money -= current_bet
	current_bet *= 2
	money_label.text = "$" + str(player_money)
	bet_label.text = "BET: $" + str(current_bet)
	
	# Deal one more card and stand
	deal_card(player_cards, false)
	update_score(player_cards, player_score_label)
	
	var player_score = int(player_score_label.text)
	if player_score > 21:
		player_bust()
	else:
		player_stand()

func player_bust():
	end_game("BUST! You lose.")

func dealer_turn():
	# Dealer draws until 17 or higher
	var dealer_score = calculate_score(dealer_cards)
	
	while dealer_score < 17:
		deal_card(dealer_cards, false)
		dealer_score = calculate_score(dealer_cards)
		update_score(dealer_cards, dealer_score_label)
		
		# Add a brief delay for animation
		await get_tree().create_timer(1.0).timeout
	
	determine_winner()

func determine_winner():
	var player_score = int(player_score_label.text)
	var dealer_score = int(dealer_score_label.text)
	
	if dealer_score > 21:
		# Dealer busts
		player_money += current_bet * 2
		money_label.text = "$" + str(player_money)
		end_game("Dealer busts! You win $" + str(current_bet))
	elif dealer_score > player_score:
		# Dealer wins
		end_game("Dealer wins with " + str(dealer_score))
	elif player_score > dealer_score:
		# Player wins
		player_money += current_bet * 2
		money_label.text = "$" + str(player_money)
		end_game("You win $" + str(current_bet) + " with " + str(player_score))
	else:
		# Push - return bet
		player_money += current_bet
		money_label.text = "$" + str(player_money)
		end_game("Push - It's a tie!")

func end_game(message):
	current_state = GameState.GAME_OVER
	game_message.text = message
	
	# Enable deal button for next round
	hit_button.disabled = true
	stand_button.disabled = true
	double_button.disabled = true
	deal_button.disabled = false
	
	# Check if player is out of money
	if player_money <= 0:
		game_message.text = "Game Over! You're out of money!"
		deal_button.disabled = true

func play_sound(sound_name):
	# Load and play appropriate sound effect
	var sound = load("res://assets/audio/sfx/" + sound_name + ".ogg")
	if sound:
		sound_fx.stream = sound
		sound_fx.play()

# Button Signal Handlers
func _on_chip_pressed(value):
	if current_state == GameState.BETTING and player_money >= value:
		current_bet += value
		player_money -= value
		bet_label.text = "BET: $" + str(current_bet)
		money_label.text = "$" + str(player_money)
		deal_button.disabled = false
		
		# Play chip sound
		play_sound("chip_place")

func _on_deal_button_pressed():
	if current_bet > 0:
		init_game()
		deal_initial_cards()
		current_state = GameState.PLAYER_TURN
		deal_button.disabled = true

func _on_hit_button_pressed():
	if current_state == GameState.PLAYER_TURN:
		player_hit()

func _on_stand_button_pressed():
	if current_state == GameState.PLAYER_TURN:
		player_stand()

func _on_double_button_pressed():
	if current_state == GameState.PLAYER_TURN and player_money >= current_bet:
		player_double()

func _on_menu_button_pressed():
	# Return to title screen
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_chip_5_pressed():
	increase_bet(5)
	$BettingArea/BetAmount.text = str(current_bet)

func _on_chip_10_pressed():
	increase_bet(10)

func _on_chip_25_pressed():
	increase_bet(25)

func _on_chip_100_pressed():
	increase_bet(100)
