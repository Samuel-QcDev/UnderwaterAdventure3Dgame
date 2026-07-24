# PlayerState.gd

extends Node

# Global variables to track player state
var has_shrunk := false
var is_alive := true
var coin_count := 0
var max_coins := 100

func reset():
	has_shrunk = false
	is_alive = true
	coin_count = 0
