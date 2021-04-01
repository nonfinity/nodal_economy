extends Control

var model_object: Economy_Directed.EconRoute = null

func update_display():
	if model_object == null:
		# bail the hell out!
		return
	
	$Sorter/values/source.text = model_object.source.name
	$Sorter/values/sink.text = model_object.sink.name
	
	var cap_text: String = ""
	cap_text = "%.0f / %.0f" % [model_object.capacity.taken, model_object.capacity.total]
	$Sorter/capacity/Value.text = cap_text
