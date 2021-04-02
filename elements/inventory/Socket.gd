extends PanelContainer

var model_object: Economy_Inventory.GoodSocket

onready var text_slots = {
	'prod' : $Sorter/Grid/prod,
	'cons' : $Sorter/Grid/cons,
	'inv' : $Sorter/Grid/inv,
	'supply' : $Sorter/Grid/supply,
	'demand' : $Sorter/Grid/demand,
	'price' : $Sorter/Grid/price,
}

func _ready():
	for i in text_slots.keys():
		text_slots[i].set_label(i)
		text_slots[i].set_value("")

func update_display():
	if model_object == null:
		# bail the hell out!
		return

	var toString: Dictionary = {
		'prod' : "%.1f" % model_object.production.get_value(),
		'cons' : "%.1f" % model_object.consumption.get_value(),
		#'inv' : "%.1f" % model_object.inventory,
		'inv' : "%.1f" % model_object.inventory.get_value(),
		'supply' : "%.1f" % model_object.supply.get_value(1),
		'demand' : "%.1f" % model_object.demand.get_value(1),
		'price' : str("%.2f" % model_object.price),
	}
	
	for i in toString.keys():
		text_slots[i].set_value(toString[i])
	pass
