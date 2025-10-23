extends Node2D 

signal piece_chosen(piece_type: int)

var player_id := 1

@onready var menu_container = %MarginContainer
const FIXED_POSITION = Vector2(72.0, 77.0) 

func _ready():
	# Ensure the menu is initially hidden
	hide()
	#to make use the input dosent affect the boarding behind the menu
	menu_container.mouse_filter = Control.MOUSE_FILTER_STOP
	#to keep input handling on even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS


# Call this from Board.gd to display the menu and center it on the screen
func show_menu_centered(current_player_id: int):
	player_id = current_player_id
	
	# Pause the game logic immediately
	get_tree().paused = true
	
	#  Defer the positioning and showing logic together ---
	call_deferred("_perform_positioning_and_show")


# New function to execute the centering and showing logic safely after layout is complete.
func _perform_positioning_and_show():
	global_position = FIXED_POSITION
	
	show()  #become visible

func _handle_promotion_choice(piece_type: int):
	
	# Hide the menu and unpause the game
	get_tree().paused = false
	hide()
	
	emit_signal("piece_chosen", piece_type) #da trigger
	
	print("Promotion choice made: ", piece_type)

func _on_king_pressed() -> void:
	_handle_promotion_choice(6) # Queen ID: 5

func _on_queen_pressed() -> void:
	_handle_promotion_choice(5) # Queen ID: 5

func _on_rook_pressed() -> void:
	_handle_promotion_choice(2) # Rook ID: 2

func _on_bishop_pressed() -> void:
	_handle_promotion_choice(4) # Bishop ID: 4

func _on_knight_pressed() -> void:
	_handle_promotion_choice(3) # Knight ID: 3
