extends Control

var model_object: Economy.EconNode = null

onready var text_slots = {
	'name' : $VBoxContainer/title/HBoxContainer/name,
	'type' : $VBoxContainer/title/HBoxContainer/type,
	'supply' : $VBoxContainer/BaseInfo/sup_nat/HBoxContainer/Label2,
	'import' : $VBoxContainer/BaseInfo/sup_imp/HBoxContainer/Label2,
	'demand' : $VBoxContainer/BaseInfo/dem_nat/HBoxContainer/Label2,
	'export' : $VBoxContainer/BaseInfo/dem_exp/HBoxContainer/Label2,
	'providing' : $VBoxContainer/CompInfo/prov/HBoxContainer/Label2,
	'requesting' : $VBoxContainer/CompInfo/req/HBoxContainer/Label2,
	'netflow' : $VBoxContainer/CompInfo/netflow/HBoxContainer/Label2,
	'gafx' : $VBoxContainer/CompInfo/gafx/HBoxContainer/Label2,
	'price' : $VBoxContainer/price/HBoxContainer/Label2,
}

func _ready():
	for i in text_slots.values():
		i.text = ""

func update_display():
	if model_object == null:
		# bail the hell out!
		return
	
	# name
	text_slots.name.text = model_object.name
	
	# type
	var type_string: String = ""
	match model_object.type:
		Economy.nodetype.HUB:
			type_string = "HUB"
		Economy.nodetype.POOL:
			type_string = "POOL"
		_:
			type_string = "OTHER"	
	text_slots.type.text = type_string
	
	
	var toString: Dictionary = {}
	toString.supply = str("%.0f" % model_object.supply_native)
	toString.import = str("%.0f" % model_object.supply_import)
	toString.demand = str("%.0f" % model_object.demand_native)
	toString.export = str("%.0f" % model_object.demand_export)
	
	toString.providing = str("%+.0f" % model_object.goods_provided())
	toString.requesting = str("%+.0f" % model_object.goods_requested())
	toString.netflow = str("%+.0f" % model_object.goods_net_flow())
	toString.gafx = str("%+.0f" % model_object.goods_available_for_export())
	toString.price = str("%.2f" % model_object.price)
	
	for i in toString.keys():
		text_slots[i].text = toString[i]	
	pass
