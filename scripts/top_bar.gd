# TopBar.gd
extends Control

signal formation_changed(formation_type)

@onready var formation_dropdown = $HBoxContainer/FormationDropdown

var formations = {
	"Line Formation": "line",
	"Grid Formation": "grid"
}

func _ready():
	# Populate dropdown
	for formation_name in formations.keys():
		formation_dropdown.add_item(formation_name)
	
	# Select the default formation (line)
	for i in range(formation_dropdown.item_count):
		if formation_dropdown.get_item_text(i) == "Line Formation":
			formation_dropdown.select(i)
			break
	
	# Connect signal
	formation_dropdown.item_selected.connect(_on_formation_selected)

func _on_formation_selected(index):
	var formation_name = formation_dropdown.get_item_text(index)
	var formation_type = formations[formation_name]
	formation_changed.emit(formation_type)

# Method to select a specific formation programmatically
func select_formation(formation_type):
	for i in range(formation_dropdown.item_count):
		var item_text = formation_dropdown.get_item_text(i)
		if formations[item_text] == formation_type:
			formation_dropdown.select(i)
			break
