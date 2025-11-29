class_name ManagerPathfinding
extends Node

@export var tile_map_grid : TileMapLayer 
@export var end_point : Marker2D

# Static singleton reference for convenience static 
static var instance: ManagerPathfinding = null

var astar_grid : AStarGrid2D = AStarGrid2D.new()

func _ready() -> void: 
	instance = self
	setup_astar_grid() 

func setup_astar_grid() -> void:
	astar_grid.region = tile_map_grid.get_used_rect()
	astar_grid.cell_size = tile_map_grid.tile_set.tile_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	update_terrain_movement_values()

func update_terrain_movement_values() -> void:
	for i in tile_map_grid.get_used_cells():
		if get_cell_movement_cost(i) < 10:
			astar_grid.set_point_weight_scale(i, get_cell_movement_cost(i))
		else:
			astar_grid.set_point_solid(i, true)

func get_valid_path(start_position: Vector2) -> Array[Vector2i]:
	var path_array : Array[Vector2i] = []
	#print_debug(end_point)
	if end_point == null:
		push_warning("ManagerPathfinding target_pos not assigned!")
		return path_array
	
	for point in astar_grid.get_point_path(start_position, end_point.global_position / 64):
		var current_point : Vector2i = point
		current_point += astar_grid.cell_size / 2 as Vector2i
		path_array.append(current_point)
	return path_array

func get_cell_movement_cost(cell_position : Vector2i) -> int:
	return tile_map_grid.get_cell_tile_data(cell_position).get_custom_data_by_layer_id(1)
