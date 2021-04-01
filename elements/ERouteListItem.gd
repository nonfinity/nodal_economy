extends Control

var model_object: Economy.EconRoute = null

func update_display():
	if model_object == null:
		# bail the hell out!
		return
	
	$Sorter/side_a/Sorter/Value.text = model_object.side_A.name
	$Sorter/side_b/Sorter/Value.text = model_object.side_B.name
	$Sorter/capacity/Sorter/Value.text = str("%.0f" % model_object.capacity.total)
	
	var cap_taken: float = model_object.capacity.taken
	
	var set_flip = false if cap_taken >= 0 else true
	
	$Sorter/flow/Sorter/Arrow.flip_h = set_flip
	$Sorter/flow/Sorter/Value.text = str("%.0f" % abs(cap_taken))
	
	
