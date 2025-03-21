class_name State
extends Node

signal state_transition_requested(new_state: String)

var unit: CharacterBody2D

func enter(): pass
func exit(): pass
func physics_update(_delta: float): pass
