extends Node


class_name Economy_Directed

var nodes: Array = []
var routes: Array = []

var transport_queue: Array = []

var is_balanced: bool = false
var checksum: int  = 0
var rng = RandomNumberGenerator.new()

var step_count: int = 0

func r(low, high) -> int:
	var wide5 = (high-low)/5
	return round(rng.randf() * wide5) * 5 + low

func build_spain_test():
	rng.randomize()
	
	var src = EndPoint.new(1, "All Source", true)
	var snk = EndPoint.new(2, "All Sink", false)
	
	var m = EconNode.new(3, "Malaga")
	var v = EconNode.new(4, "Valencia")
	var b = EconNode.new(5, "Barcelona")
	var r = EconNode.new(6, "Spain Roads")
	
	add_node(src, true)
	add_node(snk, true)
	add_node(m, true)
	add_node(v, true)
	add_node(b, true)
	add_node(r, true)
	
	var rnds: Array = []
	for _i in range(10):
		rnds.push_back(r(10,200))
	
	var temp_routes = [
		# connections to source
		EconRoute.new(1, src, m, rnds[0]),
		EconRoute.new(2, src, v, rnds[1]),
		EconRoute.new(3, src, b, rnds[2]),
	
		# connections to sink
		EconRoute.new(4, m, snk, rnds[3]),
		EconRoute.new(5, v, snk, rnds[4]),
		EconRoute.new(6, b, snk, rnds[5]),
		
		# cities -> roads
		EconRoute.new(7, m, r, rnds[6]),
		EconRoute.new(8, v, r, rnds[7]),
		EconRoute.new(9, b, r, rnds[8]),
		
		# roads -> cities
		EconRoute.new(10, r, m, rnds[6]),
		EconRoute.new(11, r, v, rnds[7]),
		EconRoute.new(12, r, b, rnds[8]),
	]
	
	for i in temp_routes:
		add_route(i, true)
	
	set_dirty()
	write_state_to_file(true)
	pass
# put economy wide stuff here

func get_node_by_name(which: String) -> EconNode:
	var out: EconNode
	for i in nodes:
		if i.name == which:
			out = i
			break
	return out

func get_node_by_id(which: int) -> EconNode:
	var out: EconNode
	for i in nodes:
		if i.id == which:
			out = i
			break
	return out

func get_route_by_id(which: int) -> EconRoute:
	var out: EconRoute
	for i in routes:
		if i.id == which:
			out = i
			break
	assert(out != null, "did not find route by id!")
	return out

func add_node(new_node: EconNode, bypass_dirty_flag: bool = false):
	nodes.push_back(new_node)
	if not bypass_dirty_flag:
		set_dirty()

func add_route(new_route: EconRoute, bypass_dirty_flag: bool = false):
	routes.push_back(new_route)
	if not bypass_dirty_flag:
		set_dirty()

func set_dirty():
	is_balanced = false
	checksum = calculate_checksum()

func current_state() -> Dictionary:
	var out: Dictionary = {
		"config": {
			"is_balanced": is_balanced,
			"step_count": step_count,
		},
		"nodes": {},
		"routes": {},
		"queue": transport_queue,
	}
	
	for i in nodes:
		var x = {
			"name": i.name,
			"type": i.type,
			"price": i.price,
			"import": i.import,
			"export": i.export,
			"requested": i.goods_requested(),
			"provided": i.goods_provided(),
			"net_flow": i.goods_net_flow(),
		}
		out.nodes[i.id] = x
	
	for i in routes:
		var x = {
			"source_name": i.source.name,
			"source_id": i.source.id,
			"sink_name": i.sink.name,
			"sink_id": i.sink.id,
			"capacity": i.capacity,
			"source_share": i.source.calculate_route_share(i)
		}
		x.capacity.available = i.available_capacity()
		out.routes[i.id] = x
	
	return out

func serialize() -> Array:
	var out: Array = []
	
	for i in nodes:
		out.push_back(serialize_one(i))
	
	for i in routes:
		out.push_back(serialize_one(i))
	
	for i in transport_queue:
		out.push_back(serialize_one(i))
	
	return out

func serialize_one(which) -> Dictionary:
	var out: Dictionary = {}
	
	var element_list = [
		"is_balanced", "step_count", "id", "name", "type",
		"export_commited", "export_queued", "import_commited", "import_commited", "requested", "provided", "net_flow", "price",
		"source_name", "source_id", "sink_name", "sink_id", "source_share", "capacity_total", "capacity_taken", "capacity_queued", "capacity_available",
		"good_id", "quantity", "route_id"
	]
	
	for i in element_list:
		if not out.has(i):
			out[i] = null
	
	out.is_balanced = is_balanced
	out.step_count = step_count
	
	match which.type:
		"Node", "Endpoint":
			out.id = which.id
			out.name = which.name
			out.type = which.type
			out.export_commited = which.export.commited
			out.export_queued = which.export.queued
			out.import_commited = which.import.commited
			out.import_commited = which.import.queued
			out.requested = which.goods_requested()
			out.provided = which.goods_provided()
			out.net_flow = which.goods_net_flow()
			out.price = which.price
		"Route":
			out.id = which.id
			out.type = which.type
			out.source_name = which.source.name
			out.source_id = which.source.id
			out.sink_name = which.sink.name
			out.sink_id = which.sink.id
			out.source_share = which.source.calculate_route_share(which)
			out.capacity_total = which.capacity.total
			out.capacity_taken = which.capacity.taken
			out.capacity_queued = which.capacity.queued
			out.capacity_available = which.available_capacity()
		"Transport":
			out.type = which.type
			out.good_id = which.good_id
			out.quantity = which.quantity
			out.route_id = which.route_id
		_:
			pass
	
	return out

func calculate_checksum() -> int:
	var out: int = 0
	
	var hash_target: Array = []
	for i in nodes:
		hash_target.push_back(i.price)
	
	out = hash(hash_target)
	return out

func execute_transport_queue():
	while transport_queue.size() > 0:
		var i = transport_queue.pop_front()
		var route = get_route_by_id(i.route_id)
		route.execute_trasport(i.quantity, i.good_id)

func market_step():
	if is_balanced:
		pass # why try harder?
	else:
		step_count += 1
		print("\nMarket Step %d" % step_count)
		for i in nodes:
			i.requested.is_dirty = true
		
		for i in routes:
			#var prop_transport: Dictionary = i.calculate_transport()
			var prop_transport: Dictionary = i.queue_transport()
			if not prop_transport.empty():
				transport_queue.push_back(prop_transport)
		
		write_state_to_file()
		var tq_size = transport_queue.size()
		#print("%.0f transports added to queue from %.0f routes: " % [tq_size, routes.size()] )
		execute_transport_queue()
		
		var _x: float = 0.0
		for i in nodes:
			_x += i.goods_net_flow()
		
		var new_checksum: int = calculate_checksum()
		if new_checksum != checksum:
			checksum = new_checksum
		elif tq_size == 0:
			is_balanced = true
			print("BALANCED THIS NETWORK!")

func write_state_to_file(is_first_line: bool = false):
	var file = File.new()
	if is_first_line:
		file.open("res://debug.txt", File.WRITE)
		var csv = str(serialize()[0].keys())
		csv = csv.trim_prefix("[")
		csv = csv.trim_suffix("]")
		file.store_line(csv)
		assert(file.is_open(), "file could not be opened!")
		file.close()
	
	file.open("res://debug.txt", File.READ_WRITE)
	file.seek_end()
	#file.store_line(str(to_json(current_state()), ","))
	for i in serialize():
		var csv = str(i.values())
		csv = csv.trim_prefix("[")
		csv = csv.trim_suffix("]")
		file.store_line(csv)
	file.close()

# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
#		ECONNODE CLASS DEFINITION
# _init(node_id, node_name, node_type, supply, demand)
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
class EconNode:
	var id: int
	var routes_as_source: Array
	var routes_as_sink: Array
	var name: String
	var type: String

	var import = { 'commited': 0.0, 'queued': 0.0 }
	var export = { 'commited': 0.0, 'queued': 0.0 }
	
	var requested = { 'quantiy': 0.0, 'is_dirty': true }
	
	var price: float
	
	func _init(node_id: int, node_name: String, node_type: String = 'Node'):
		id = node_id
		name = node_name
		type = node_type
		price = calculate_price()
		pass
	
	func goods_requested(_good_id: int = -1, steps: int = 2,
			blacklist: Array = [], toplevel: bool = true) -> float:
		var out: float = 0.0
		
		if not requested.is_dirty:
			out = requested.quantiy
		else:
			var steps_remain = steps -  1
			if steps_remain < 0:
				out = 0.0
			else:
				#var new_blacklist = blacklist.push_back(id)
				blacklist.push_back(id)
				for i in routes_as_source:
					if not blacklist.has(i.id):
						var prop_req = i.sink.goods_requested(_good_id, steps_remain, blacklist, false)
						out += min(i.available_capacity(), prop_req)
			
			if toplevel:
				requested.quantiy = out
				requested.is_dirty = false
		return out
	
	func goods_provided(_good_id: int = -1) -> float:
		var out: float = 0.0
		# not including queued imports right now. Think it will make recursion hard
		out = max(0, import.commited - export.commited - export.queued)
		#out = max(0, import.commited + import.queued - export.commited - export.queued)
		
		return out
	
	func goods_net_flow(_good_id: int = -1) -> float:
		var out: float = 0.0
		out = goods_provided() - goods_requested()
		
		return out

	func calculate_route_share(which) -> float:
		var out: float = 0.0
		var gafx: float = goods_provided()
		var route_pct = 1.0
		
		if routes_as_source.size() > 1:
			var demands = {
				"all": { "target": 0.0, "total": 0.0 },
				"end": { "target": 0.0, "total": 0.0 }, # only when sink is Endpoint
			}
			for i in routes_as_source:
				var i_sink: EconNode = i.sink
				var is_endpoint: bool = i_sink.type == "Endpoint"
				
				var gnf: float = i_sink.goods_net_flow()
				var route_cap: float = i.available_capacity()
				var curr_demand: float = min(route_cap, max(0.0, -gnf))
				
				demands.all.total += curr_demand
				demands.all.target += curr_demand if i == which else 0.0
				demands.end.target += curr_demand if is_endpoint else 0.0
				demands.end.total += curr_demand if is_endpoint  and i == which else 0.0
				
			if demands.all.total > 0:
				var k = demands.end if demands.end.total > 0 else demands.all
				route_pct = k.target / k.total

		out = min(gafx * route_pct, which.available_capacity())
		if out > 0 and false:
			var prt = str("Route from ", which.source.name, " to ", which.sink.name)
			prt = str(prt, " calcs: %.1f" % out )
			print(prt)
		return out

	func calculate_price() -> float:
		var out: float = 0.0
		
		if type == 'Endpoint':
			return out
			# no price for you!
		
		var mkt = {
			'supply': { 'coeff': -0.25, 'intercept': 15.0 },
			'demand': { 'coeff':  0.20, 'intercept': 10.0 },
		}
		var gafx = goods_net_flow()
		var equibX: float = 0
		
		equibX += gafx * (mkt.supply.coeff + mkt.demand.coeff)
		equibX += mkt.supply.intercept - mkt.demand.intercept
		equibX /= (mkt.demand.coeff - mkt.supply.coeff)
		
		out = round(100 * (mkt.supply.coeff * (gafx + equibX) + mkt.supply.intercept))
		out /= 100 # get them pennies!
		
		var print_step = false
		if print_step:
			var easyPrint = { 'name': name, 'gafx': gafx, 'equibX': equibX,'price': out }
			print( easyPrint )
		return out

	
	# ##### ##### ##### #
	# MUTATOR FUNCTIONS
	# ##### ##### ##### #
	func add_route(route: EconRoute, is_route_source: bool):
		# add check to prevent duplicate routes
		if is_route_source:
			routes_as_source.push_back(route)
		else:
			routes_as_sink.push_back(route)

	# Shipment for outbound goods, Deliveries for inbound
	#func process_shipment(route: EconRoute, good_id: int, quantity: float):
	func process_shipment(quantity: float, _good_id: int = -1):
		assert(quantity >= 0, "process_shipment() requires positive quantity numbers")
		export.commited += quantity
		export.queued -= quantity
		price = calculate_price()
		requested.is_dirty = true
	
	func process_delivery(quantity: float, _good_id: int = -1):
		assert(quantity >= 0, "process_delivery() requires positive quantity numbers")
		import.commited += quantity
		import.queued -= quantity
		price = calculate_price()
		requested.is_dirty = true

# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
#		ENDPOINT CLASS DEFINITION
# _init(node_id, node_name, node_is_source)
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
class EndPoint:
	extends EconNode
	var is_source: bool # soruce or sink, baby?
	
	func _init(node_id: int, node_name: String, node_is_source: bool).(node_id, node_name, 'Endpoint'):
		is_source = node_is_source
		pass
	
	func goods_requested(_good_id: int = -1, _steps: int = 5,
			 _blacklist: Array = [], _toplevel: bool = true) -> float:
		return 0.0 if is_source else 99999999.9
	
	func goods_provided(_good_id: int = -1) -> float:
		return 99999999.9 if is_source else 0.0

# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
#		ECONROUTE CLASS DEFINITION
# _init(route_id, source, sink, route_capacity)
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
class EconRoute:
	var id: int
	var source: EconNode
	var sink: EconNode
	var type = "Route"
	
	# flow only occurs from source -> sink
	var capacity = {
		'total': 0.0,
		'queued': 0.0,
		'taken': 0.0,
	}

	func _init(route_id:int, set_source: EconNode,
			set_sink: EconNode, route_capacity: float):
		
		id = route_id
		capacity.total = route_capacity
		
		source = set_source
		source.add_route(self, true)
		
		sink = set_sink
		sink.add_route(self, false)
	
	func available_capacity() -> float:
		return capacity.total - capacity.taken - capacity.queued

	func calculate_transport() -> Dictionary:
		var out: Dictionary = {}
		
		if id == 1:
			pass
		
		#var prv = source.goods_provided()
		#var req = sink.goods_requested()
		
		if source.goods_provided() > 0 and sink.goods_requested() > 0:
			# then flow
			var round_coeff: int = 3		# larger coeff = more iterations
			
			# possible exports from source
			var route_share: float = source.calculate_route_share(self)
			# capped by needed imports at sink
			var xfer_cap = min(route_share, abs(sink.goods_requested()))
			# round that puppy off so we don't iteratre over 0.000001
			var xfer_quantity = round(xfer_cap * round_coeff) / round_coeff
			
			# construct return dictionary if any transport will occur
			if xfer_quantity != 0:
				out = {
					'type': 'Transport',
					'route_id': id,
					'good_id': -1,
					'quantity': xfer_quantity,
				}
		
		return out
	
	func queue_transport() -> Dictionary:
		var out: Dictionary = {}
		
		out = calculate_transport()
		if not out.empty():
			capacity.queued += out.quantity
			source.export.queued += out.quantity
			sink.import.queued += out.quantity
		
		return out
	
	func execute_trasport(quantity: float, _good_id: float = -1):
		source.process_shipment(quantity)
		sink.process_delivery(quantity)
		
		capacity.queued -= quantity
		capacity.taken += quantity
		
		if false:
			var pStr = str("Route %.0f delivering %.1f from %s to %s. Cap(%.0f/%.0f)" %
					[id, quantity, source.name, sink.name, capacity.taken, capacity.total])
			print(pStr)
		pass








