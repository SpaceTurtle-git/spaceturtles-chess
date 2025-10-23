extends Node2D

var board = []

const BOARD_SIZE = 8
const CELL_SIZE = 18.0

const PIECE_SPRITES = {
	1: preload("res://my_assets/WhitePawn.png"),
	2: preload("res://my_assets/WhiteRook.png"),
	3: preload("res://my_assets/WhiteKnight.png"),
	4: preload("res://my_assets/WhiteBishop.png"),
	5: preload("res://my_assets/WhiteQueen.png"),
	6: preload("res://my_assets/WhiteKing.png"),
	-1: preload("res://my_assets/BlackPawn.png"),
	-2: preload("res://my_assets/BlackRook.png"),
	-3: preload("res://my_assets/BlackKnight.png"),
	-4: preload("res://my_assets/BlackBishop.png"),
	-5: preload("res://my_assets/BlackQueen.png"),
	-6: preload("res://my_assets/BlackKing.png"),
}

var currentTurn := 1       # 1 for white -1 for black , WHITE START
var selectedPiece = 0
var isSelected = false
var fromCoordinates = Vector2i(-1,-1)
var toCoordinates = Vector2i(-1,-1)

@onready var piece_container = $Pieces
@onready var camera2d = $"../Camera2D"
const PROMOTION_MENU_SCENE = preload("res://scene/PromotionMenu.tscn")
var promotion_menu: Node2D

var isGameOver = false 
var is_awaiting_promotion = false 
var promotion_coords = Vector2i(-1, -1) # Stores the location of the pawn to be promoted

func _ready() -> void:
	#make board
	board.resize(BOARD_SIZE)
	for i in range(BOARD_SIZE):
		board[i] = [0,0,0,0,0,0,0,0]
	#black
	board[0] = [-2,-3,-4,-6,-5,-4,-3,-2]
	board[1] = [-1,-1,-1,-1,-1,-1,-1,-1]
	#white
	board[6] = [1,1,1,1,1,1,1,1]
	board[7] = [2,3,4,5,6,4,3,2]
	
	# Instantiate the node 
	promotion_menu = PROMOTION_MENU_SCENE.instantiate()
	#used call deferred cause i was getting breakpoint error because ts was instantiating while main was loading
	call_deferred("add_child", promotion_menu) 
	
	# We wait until the node is definitely added to the tree to connect the signal.
	if promotion_menu.is_connected("piece_chosen", Callable(self, "_on_promotion_piece_chosen")) == false:
		promotion_menu.piece_chosen.connect(_on_promotion_piece_chosen)
	
	move_piece(Vector2i(0,0),Vector2i(4,4))
	display_board()

#custom functions

func move_piece(from: Vector2i,to: Vector2i):
	
	if isGameOver == true:
		print("Game is over.")
		return
	
	#Safety Measures
	if selectedPiece == 0:             #is there a piece
		print("No Piece Found")
		return
	if sign(selectedPiece) != currentTurn:   # is it your turn
		print('Not Your Turn Buddy')
		return
	if from == to:                     # is the move on a different cell
		print("Can't Move In Same Place")
		return
	if not is_move_valid(from,to,selectedPiece):     #is the move valid for the piece
		print("Move Aint Valid Broksi")
		return
	if not can_this_be_captured(from,to):  # is the move on a friendly or a opp
		print('Friendly Fire is Disabled')
		return
	if not is_move_safe(from,to,selectedPiece):   #if move puts u in a check 
		print('Dont put yourself in check')
		return
	
	#move
	board[to.x][to.y] = selectedPiece          #destination cell changed
	board[from.x][from.y] = 0                  #origin cell resetted to clear
	print("Moved %s from %s to %s" % [selectedPiece, from, to])
	
	if promotion_check(from,to,selectedPiece):
		pass    #check if promotion move was made
	else: 
		complete_turn()

func promotion_check(from: Vector2i,to: Vector2i,piece_moved: int) -> bool:
	if abs(piece_moved) == 1: # Is it a pawn?
		var promotion_rank = 0 if currentTurn == 1 else 7 # White promotes at row 0, Black at row 7
		
		if to.x == promotion_rank:
			
			is_awaiting_promotion = true
			promotion_coords = to
			if currentTurn == -1:
				promotion_menu.rotation_degrees = 180
			else:
				promotion_menu.rotation_degrees = 0
			#  Show the promotion menu (passing currentTurn allows menu to display correct piece colors)
			promotion_menu.call_deferred("show_menu_centered", currentTurn)
			print("Pawn promotion triggered. Awaiting selection...")
			clear_board_display()
			display_board()
			# promotion complete
			return true
	return false

func complete_turn():
	#turn change
	currentTurn *= -1                  #swtiches turn if , if turn is 1 *= does 1x-1 and if -1 it does -1x-1 thats how it works 
	#Check for check and stalemate
	var is_currently_in_check = is_in_check(currentTurn)
	var has_moves = has_legal_moves(currentTurn)
	
	if not has_moves:
		if is_currently_in_check:
			var winner = 'Black' if currentTurn == 1 else 'White'
			print("CHECKMATE! " + winner + " Wins!")
			isGameOver = true
		else:
			print('Stalemate')
			isGameOver = true
			
	elif is_currently_in_check:
		print('Check')
	#Flip camera logic
	if currentTurn == 1:               
		camera2d.rotation_degrees = 0
	else:
		camera2d.rotation_degrees = 180
	
	clear_board_display()
	display_board()

func _on_promotion_piece_chosen(new_piece_type: int):
	if not is_awaiting_promotion: 
		print("NOT WAITING PROMOTION how u triggered this")
		return
	# The player whose turn it was is still currentTurn at this point
	var player_id = sign(board[promotion_coords.x][promotion_coords.y])
	var new_piece_id = new_piece_type * player_id    #change the piece to same team
	
	board[promotion_coords.x][promotion_coords.y] = new_piece_id
	
	print("Pawn promoted to ", new_piece_id)
	
	# Reset the promotion flags
	is_awaiting_promotion = false
	promotion_coords = Vector2i(-1, -1)
	
	complete_turn()

func clear_board_display():
	# Helper to remove all existing sprites before redrawing
	for child in piece_container.get_children():
		if child is Sprite2D:
			child.queue_free()

func display_board():
	for x in BOARD_SIZE: 
		for y in BOARD_SIZE:          # Y IS ROW X IS COLUMN
			var piece = board[y][x]   # APPARENTLY IT GOES COLUM BY COLUMN 
			if piece != 0 :
				var sprite = Sprite2D.new()
				sprite.texture = PIECE_SPRITES[piece]
				sprite.position = Vector2(x*CELL_SIZE+CELL_SIZE/2,y*CELL_SIZE+CELL_SIZE/2)# cell_size/2 is added to center
				if currentTurn == 1:                # flip pawns logic
					sprite.rotation_degrees = 0
				else:
					sprite.rotation_degrees = 180
				piece_container.add_child(sprite)

func is_move_valid(from: Vector2i,to: Vector2i,piece_id: int):
	match abs(piece_id):
		1:
			return move_Pawn(from,to)
		2: 
			return move_Rook(from,to) 
		3:
			return move_Knight(from,to)
		4:
			return move_Bishop(from,to)
		5:
			return move_Queen(from,to)
		6:
			return move_King(from,to)
		_:
			print ("Piece not in data something went wrong")
			return false

#updating functions

func _input(event: InputEvent) -> void:
	#block input for these states
	if is_awaiting_promotion or isGameOver:
		return
	#get coords
	if event.is_action_pressed("mouseClick"):
		var mouse_position = get_global_mouse_position()
		var column = floor(mouse_position.x/CELL_SIZE) 
		var row = floor(mouse_position.y/CELL_SIZE) 
		var board_coordinates = Vector2i(
			clamp(row, 0, BOARD_SIZE - 1),
			clamp(column, 0, BOARD_SIZE - 1)   # row,column as x,y
		)
		
		if isSelected != true:
			if board[row][column] != 0:       
				#print(board[row][column])
				fromCoordinates = board_coordinates      # selecting logic
				selectedPiece =  board[fromCoordinates.x][fromCoordinates.y]
				isSelected = true
		else: 
			toCoordinates = board_coordinates            # move trigger
			move_piece(fromCoordinates,toCoordinates)
			isSelected = false
			selectedPiece = 0   # reset 
		



#piece move functions

func move_Rook(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var path_is_straight_in_1D = (vertical_distance > 0 and horizontal_distance == 0) or (vertical_distance == 0 and horizontal_distance > 0)
	if path_is_straight_in_1D:
		return is_path_clear(from,to)
	else:
		return false

func move_Bishop(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var path_is_diagonal = vertical_distance == horizontal_distance
	if path_is_diagonal:
		return is_path_clear(from,to)
	else:
		return false

func move_Queen(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var path_is_in_1D = (vertical_distance == horizontal_distance) or (vertical_distance > 0 and horizontal_distance == 0) or (vertical_distance == 0 and horizontal_distance > 0)
	if path_is_in_1D:
		return is_path_clear(from,to)
	else:
		return false

func move_King(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var path_is_king_like = (vertical_distance <= 1) and (horizontal_distance <=1 )
	if path_is_king_like:
		return true
	else:
		return false

func move_Knight(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var path_is_knight_like = (vertical_distance == 1 and horizontal_distance == 2) or (vertical_distance == 2 and horizontal_distance == 1)
	if path_is_knight_like:
		return true
	else:
		return false

func move_Pawn(from: Vector2i,to: Vector2i):
	var vertical_distance = abs(to.x-from.x)
	var horizontal_distance = abs(to.y-from.y)
	var vertical_displacement = to.x - from.x  #negative fpw white positive for black  APPRENTLY I KEEP FORGETTING X IS COLUMN
	var pawn_id = selectedPiece
	var pawn_isWhite = pawn_id > 0 
	var start_row = 6 if pawn_isWhite else 1
	var forward_direction_sign = -1 if pawn_isWhite else 1 
	
	# does tile we are moving to have a capturable piece 
	if horizontal_distance == 1 and vertical_distance == 1 and board[to.x][to.y] !=0 :
		return true
	#check for horizontal movement shud be false
	if horizontal_distance != 0:
		return false
	#check move direction
	if sign(vertical_displacement) != forward_direction_sign:    #sign returns -1 or 1 depending on u guess it SIGN
		return false
	#check for starting move and future moves
	if vertical_distance == 1:
		return true
	elif vertical_distance == 2:
		return from.x == start_row  # didnt know ts would return a bool
	else:
		return false        #any other move

#safety functions

func can_this_be_captured(_from: Vector2i,to: Vector2i) -> bool:
	var target_cell = board[to.x][to.y]
	if sign(selectedPiece) == sign(target_cell):
		return false
	else:
		return true

func is_path_clear(from: Vector2i,to: Vector2i):
	# get 1 step for the total distance like 1 or -1
	var vertical_step = sign(to.x-from.x)
	var horizontal_step = sign(to.y-from.y)
	# check from next cell to avoid getting blocked at first step
	var current_x = from.x + vertical_step
	var current_y = from.y + horizontal_step
	
	#iterate through cells till u reach destination
	while current_x != to.x or current_y != to.y:   #WHILE LOOP runs till it is in true state 
		if board[current_x][current_y] != 0:        #with current arrangement it will keep running till
			#print('Path Blocked')                   #current_x and current_y BOTH return flase on != to.x and to.y
			return false                              #commented out path blocked because it was running every loop in king check logic
		current_x += vertical_step                   
		current_y += horizontal_step
	return true

#checking logic 
func find_king_position(player_id: int) -> Vector2i:
	var king_id = 6 * player_id
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			if board[x][y] == king_id:
				return Vector2i(x, y)
	return Vector2i(-1, -1) # Should not happen in a valid game

func is_in_check(player_id:int) -> bool:
	var king_pos = find_king_position(player_id)
	var attacking_player_id = -player_id
	
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var piece_id = board[x][y]
			
			if sign(piece_id) == attacking_player_id:
				var attacker_pos = Vector2i(x,y)
				
				if is_move_valid(attacker_pos,king_pos,piece_id):
					return true
	return false

func is_move_safe(from: Vector2i, to: Vector2i, piece_id: int) -> bool:
	var player_id = sign(piece_id)
	var original_from_piece = board[from.x][from.y]
	var original_to_piece = board[to.x][to.y]
	
	board[to.x][to.y] = piece_id
	board[from.x][from.y] = 0
	
	var is_currently_in_check = is_in_check(player_id)
	
	board[to.x][to.y] = original_to_piece
	board[from.x][from.y] = original_from_piece
	
	return not is_currently_in_check
	
func has_legal_moves(player_id: int) -> bool:
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:        #first 2d loop to find a piece
			
			var piece_id = board[x][y]        #whatis the piece at location
			if sign(piece_id) == player_id:   #if piece belong to my team
				var from = Vector2i(x,y)      
				
				for x2 in BOARD_SIZE:          #2nd 2d loop to check all possible moves of the piece we found
					for y2 in BOARD_SIZE:
						var to = Vector2i(x2,y2)
						
						if from == to:          # optional but saves some performance skipping the same tile
							continue
						if is_move_valid(from,to,piece_id):    #check if move valid for selected piece
							var target_piece = board[x2][y2]      #checks what piece is at to location and if its same team
							if sign(target_piece) == player_id:
								continue
							if is_move_safe(from,to,piece_id):     #checks if move puts us in a check
								#print(from,to)
								return true
	#loop finished without finding a single legal move
	return false
