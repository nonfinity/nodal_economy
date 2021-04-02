extends Node2D

var e: Economy_Inventory = Economy_Inventory.new()


func _ready():
	# load up e
	e.build_spain_test()
	
	# assign hubs to scene elemends
	for i in $Hubs.get_children():
		var fetch_name: String = i.name
		i.prep_element(e.get_item_by_name(fetch_name, e.TYPES.HUB))
	pass
	
	for i in $Routes.get_children():
		var fetch_id: int = int(i.name.right(2))
		i.prep_element(e.get_item_by_id(fetch_id, e.TYPES.ROUTE))
	pass
	
	pass

func _process(_delta):
	# execute economy balance?
	
	for i in $Hubs.get_children():
		i.update_display()
	
	for i in $Routes.get_children():
		i.update_display()


func _on_StepButton_pressed():
	e.tick(1.0)
	
	pass # Replace with function body.
