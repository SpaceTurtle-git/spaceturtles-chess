extends Control

# A custom signal that the ChessBoard will listen to.
# It passes the absolute piece ID (5=Queen, 2=Rook, etc.)
signal piece_chosen(new_piece_id)

# Mapping of button names to their absolute piece ID values (always positive)
const PIECE_IDS = {
	"QueenButton": 5,
	"RookButton": 2,
	"BishopButton": 4,
	"KnightButton": 3
}

func _ready():
	# Connect all buttons to a single handler function
	# Assuming the buttons are children of a VBoxContainer named VBoxContainer
	var vbox = $MarginContainer/VBoxContainer
	if vbox:
		for child in vbox.get_children():
			if child is Button:
				# Connect the "pressed" signal, binding the button's name as an argument
				child.pressed.connect(Callable(self, "_on_piece_button_pressed").bind(child.name))
	
	hide() # Ensure it starts hidden

# Central handler for all promotion button presses
func _on_piece_button_pressed(button_name: String):
	var new_id = PIECE_IDS.get(button_name)
	if new_id != null:
		# Emit the signal back to the ChessBoard with the chosen piece ID
		piece_chosen.emit(new_id)
		# Hide the menu immediately after a choice is made
		hide()

# Public function for the ChessBoard to call when promotion is needed
func show_menu_centered():
	# Set the anchors/layout to center the menu
	# Since we set the Layout > Center Rect preset in the editor,
	# we just need to ensure the VBoxContainer is centered and the root Control node is visible.
	
	# We will adjust the position of the root node relative to the main viewport.
	var viewport_size = get_viewport_rect().size
	var margin_container = $MarginContainer
	
	# Calculate the size and center the margin container itself
	var content_size = margin_container.get_combined_minimum_size()
	var centered_position = (viewport_size / 2) - (content_size / 2)

	# Note: If you set the layout of the root PromotionMenu to Center Rect in the editor, 
	# Godot handles the positioning automatically when it's made visible.
	
	# Let's assume standard Godot UI centering for now and just show it.
	show()
