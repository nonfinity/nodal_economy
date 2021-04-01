extends Node2D

var e: Economy = Economy.new()


func _ready():
	# load up e
	e.build_spain_test()
	
	# assign nodes to scene elemends
	$Nodes/Malaga.model_object = e.get_node_by_name("Malaga")
	$Nodes/Valencia.model_object = e.get_node_by_name("Valencia")
	$Nodes/Barcelona.model_object = e.get_node_by_name("Barcelona")
	$Nodes/Spain.model_object = e.get_node_by_name("Spain Roads")
	
	$RouteItems/ERouteListItem01.model_object = e.get_route_by_id(1)
	$RouteItems/ERouteListItem02.model_object = e.get_route_by_id(2)
	$RouteItems/ERouteListItem03.model_object = e.get_route_by_id(3)
	pass

func _process(_delta):
	# execute economy balance?
	
	for i in $Nodes.get_children():
		i.update_display()
	
	for i in $RouteItems.get_children():
		i.update_display()


func _on_StepButton_pressed():
	e.market_step()
	
	if e.is_balanced:
		$balance/VBoxContainer/Value.text = "EQUILIBRIUM!"
	else:
		$balance/VBoxContainer/Value.text = "Out of balance"
	
	pass # Replace with function body.
