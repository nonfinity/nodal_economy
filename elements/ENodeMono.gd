extends Control

var model_object: Economy_Directed.EconNode = null

onready var text_slots = {
	'name' : $Sorter/title/name,
	'import' : $Sorter/grid/import/HBoxContainer/Label2,
	'export' : $Sorter/grid/export/HBoxContainer/Label2,
	'provide' : $Sorter/grid/provide/HBoxContainer/Label2,
	'request' : $Sorter/grid/request/HBoxContainer/Label2,
	'price' : $Sorter/price/HBoxContainer/Label2,
}

func _ready():
	for i in text_slots.values():
		i.text = ""

func update_display():
	if model_object == null:
		# bail the hell out!
		return

	var toString: Dictionary = {
		'name' : model_object.name,
		'import' : str("%.0f" % model_object.import.commited),
		'export' : str("%.0f" % model_object.export.commited),
		'price' : str("%.2f" % model_object.price),
	}
	
	var t
	t = model_object.goods_provided()
	toString.provide = "Inf" if t > 1000000 else str("%+.0f" % t)
	
	t = model_object.goods_requested()
	toString.request = "Inf" if t > 1000000 else str("%+.0f" % t)
	
	for i in toString.keys():
		text_slots[i].text = toString[i]	
	pass
