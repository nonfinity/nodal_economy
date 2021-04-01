extends Control

var model_object: Economy.EconRoute = null

func update_display():
	if model_object == null:
		# bail the hell out!
		return
	
	var toString: Dictionary = {}
	toString.gafx_a = str("%+.0f" % model_object.side_A.goods_net_flow())
	toString.gafx_b = str("%+.0f" % model_object.side_A.goods_net_flow())
	toString.cap_total = str("%.0f" % model_object.capacity.total)
	toString.cap_taken = str("%.0f" % model_object.capacity.taken)
	
	$CapBox/Sorter/Value.text = str(toString.cap_taken, " / ", toString.cap_total)
	$SideA/Sorter/Value.text = toString.gafx_a
	$SideB/Sorter/Value.text = toString.gafx_b
	pass

func update_rotations():
	var rot_adj = -get_rotation()
	$CapBox.set_rotation(rot_adj)
	$SideA.set_rotation(rot_adj)
	$SideB.set_rotation(rot_adj)
	
	pass
