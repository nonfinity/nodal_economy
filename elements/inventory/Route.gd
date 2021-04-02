extends PanelContainer

var model_object: Economy_Inventory.Route


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sorter/Endpoints/source.set_label("Source")
	$Sorter/Endpoints/sink.set_label("Sink")
	$Sorter/Notes/dist.set_label("Dist")
	$Sorter/Notes/cap.set_label("Cap")

func prep_element(obj: Economy_Inventory.Route):
	model_object = obj
	
	$Sorter/Endpoints/source.set_value(model_object.source.name)
	$Sorter/Endpoints/sink.set_value(model_object.sink.name)
	$Sorter/Notes/dist.set_value("%.1f" % model_object.distance)
	$Sorter/Notes/cap.set_value("0.0 / %.1f" % model_object.capacity.total)

func update_display():
	var cap_used = model_object.capacity.taken + model_object.capacity.queued
	var update_text = "%.1f / %.1f" % [cap_used, model_object.capacity.total]
	
	$Sorter/Notes/cap.set_value(update_text)
