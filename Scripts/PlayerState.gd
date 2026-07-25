# PlayerState.gd

extends Node

# Global variables to track player state
var has_shrunk := false
var is_alive := true
var coin_count := 0          # optional bonus gold (not the win condition)
var max_coins := 100
var keys_collected := 0      # the win condition: bring these to the galleon

func reset():
	has_shrunk = false
	is_alive = true
	coin_count = 0
	keys_collected = 0
