extends Node2D

var e: Economy_Directed = Economy_Directed.new()

var checks = {
		'source': 0.0,
		'sink': 0.0,
		'outRoad': 0.0,
		'inRoad': 0.0,
		'net1': 0.0,
		'net2': 0.0,
	}

func _ready():
	# load up e
	e.build_spain_test()
	
	# assign nodes to scene elemends
	$Nodes/Source.model_object = e.get_node_by_name("All Source")
	$Nodes/Sink.model_object = e.get_node_by_name("All Sink")
	$Nodes/Malaga.model_object = e.get_node_by_name("Malaga")
	$Nodes/Valencia.model_object = e.get_node_by_name("Valencia")
	$Nodes/Barcelona.model_object = e.get_node_by_name("Barcelona")
	$Nodes/Roads.model_object = e.get_node_by_name("Spain Roads")
	
	for i in $Routes.get_children():
		var fetch_id: int = int(i.name.right(2))
		i.model_object = e.get_route_by_id(fetch_id)
	pass

func _process(_delta):
	# execute economy balance?
	clear_checkers()
	
	for i in $Nodes.get_children():
		i.update_display()
	
	for i in $Routes.get_children():
		i.update_display()
		var j = i.model_object
		checks.source += j.capacity.taken if j.source.name == "All Source" else 0.0
		checks.sink += j.capacity.taken if j.sink.name == "All Sink" else 0.0
		checks.inRoad += j.capacity.taken if j.sink.name == "Spain Roads" else 0.0
		checks.outRoad += j.capacity.taken if j.source.name == "Spain Roads" else 0.0
	
	update_checkers()

func clear_checkers():
	for i in checks.keys():
		checks[i] = 0.0

func update_checkers():
	checks.net1 = checks.sink - checks.source
	checks.net2 = checks.sink - checks.source + checks.inRoad - checks.outRoad
	
	for i in $Checker/Sorter.get_children():
		i.get_node("Value").text = "%.0f" % checks[i.name]
	pass

func _on_take_step_pressed():
	e.market_step()
	
	var set_text = "EQUILIBRIUM!" if e.is_balanced else "Out of balance"
	$Controls/Sorter/status/Sorter/Value.text = set_text
