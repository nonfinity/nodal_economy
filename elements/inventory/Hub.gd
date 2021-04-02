extends PanelContainer

var model_object: Economy_Inventory.Hub

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in $Sorter/Tabs.get_children():
		i.queue_free()

func prep_element(obj: Economy_Inventory.Hub):
	model_object = obj
	
	$Sorter/Label.text = model_object.name
	
	for i in model_object.sockets.keys():
		var x = load("res://elements/inventory/Socket.tscn").instance()
		x.model_object = model_object.sockets[i]
		x.set_name(i)
		$Sorter/Tabs.add_child(x)

func update_display():
	for i in $Sorter/Tabs.get_children():
		i.update_display()
