extends Node



class_name Economy

var nodes: Array = []
var routes: Array = []

var transport_queue: Array = []

enum nodetype { HUB, POOL }

var is_balanced: bool = false
var checksum: int  = 0
var rng = RandomNumberGenerator.new()

func r(low, high) -> int:
	var wide5 = (high-low)/5
	return round(rng.randf() * wide5) * 5 + low

func build_spain_test():
	rng.randomize()
	
	var m = EconNode.new(1, "Malaga", nodetype.HUB, r(50,200), r(50,200))
	var v = EconNode.new(2, "Valencia", nodetype.HUB, r(50,200), r(50,200))
	var b = EconNode.new(3, "Barcelona", nodetype.HUB, r(50,200), r(50,200))
	var s = EconNode.new(4, "Spain Roads", nodetype.POOL)
	
	add_node(m, true)
	add_node(v, true)
	add_node(b, true)
	add_node(s, true)
	
	var ms = EconRoute.new(1, m, s, r(10,200))
	var vs = EconRoute.new(2, v, s, r(10,200))
	var bs = EconRoute.new(3, b, s, r(10,200))
	
	add_route(ms, true)
	add_route(vs, true)
	add_route(bs, true)
	
	set_dirty()
	
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

func calculate_checksum() -> int:
	var out: int = 0
	
	var hash_target: Array = []
	for i in nodes:
		hash_target.push_back(i.price)
	
	out = hash(hash_target)
	return out

func execute_transport_queue():
	#for i in transport_queue:
	#	var route = get_route_by_id(i.route_id)
	#	route.execute_trasport(i.AB_quantity, i.good_id)
	
	while transport_queue.size() > 0:
		var i = transport_queue.pop_front()
		var route = get_route_by_id(i.route_id)
		route.execute_trasport(i.AB_quantity, i.good_id)

func market_step():
	if is_balanced:
		pass # why try harder?
	else:

		for i in routes:
			var prop_transport: Dictionary = i.calculate_transport()
			if not prop_transport.empty():
				transport_queue.push_back(prop_transport)
		
		var tq_size = transport_queue.size()
		print("%.0f transports added to queue from %.0f routes: " % [tq_size, routes.size()] )
		execute_transport_queue()
		
		var new_checksum: int = calculate_checksum()
		if new_checksum != checksum:
			checksum = new_checksum
		else:
			assert(tq_size == 0, "market balanced, transports were queued?!?!?!")
			is_balanced = true
			print("BALANCED THIS NETWORK!")

# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
#		ECONNODE CLASS DEFINITION
# _init(node_id, node_name, node_type, supply, demand)
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
class EconNode:
	var id: int
	var routes: Array
	var type: int		# use nodetype enum
	var name: String

	var demand_native: float
	var demand_export: float
	var supply_native: float
	var supply_import: float

	var price: float
	enum nodetype { HUB, POOL }

	func _init(node_id: int, node_name: String, node_type: int, 
			supply: float = 0, demand: float = 0):
		
		demand_native = demand
		supply_native = supply
		type = node_type
		name = node_name
		id = node_id
		
		price = calculate_price()
		pass
	
	func goods_requested(_good_id: int = -1) -> float:
		if name == "Malaga":
			pass
		
		var out: float = 0.0
		if type == nodetype.POOL:
			for i in routes:
				#out += i.available_capacity()
				out += i.get_other_side(self).goods_requested()
				#out += i.get_other_side(self).goods_net_flow()
		else:
			out = abs(min(0, goods_available_for_export()))
		return out
	
	func goods_provided(_good_id: int = -1) -> float:
		var out: float = 0.0
		out = max(0,goods_available_for_export())
		
		return out
	
	func goods_net_flow(_good_id: int = -1) -> float:
		var out: float = 0.0
		out = goods_provided() - goods_requested()
		
		return out
	
	func goods_available_for_export(_good_id: int = -1) -> float:
		return supply_native + supply_import - demand_native - demand_export

	func calculate_route_share(which) -> float:
		var out: float = 0.0
		var gafx: float = goods_provided()
		
		if name == "Spain Roads":
			pass
		
		if routes.size() == 1:
			# just cap for available bandwidth and rock out
			out = min(gafx, which.available_capacity())
		else:
			# total available capacity of routes
			var total_connected_demand: float = 0.0
			var target_connected_demand: float = 0.0
			for i in routes:
				var opp_node: EconNode = i.get_other_side(self)
				var opp_val_raw = opp_node.goods_net_flow()
				var add_val = abs(min(0, opp_val_raw))
				var capped_add = 0
				if opp_val_raw < 0:
					capped_add = min(add_val, i.available_capacity())
				
				total_connected_demand += capped_add
				if i == which:
					target_connected_demand += capped_add
			
			var route_pct = 1.0
			if total_connected_demand > 0:
				route_pct = target_connected_demand / total_connected_demand
			out = gafx * route_pct

		return out
	
	func calculate_price() -> float:
		var out: float = 0.0
		
		if type == nodetype.POOL:
			return out
			# no price for you!
		
		var mkt = {
			'supply': { 'coeff': -0.25, 'intercept': 15.0 },
			'demand': { 'coeff':  0.20, 'intercept': 10.0 },
		}
		
		#var gafx = supply_native + supply_import - demand_native - demand_export
		var gafx = goods_net_flow()
		
		var equibX: float = 0
		equibX += gafx * (mkt.supply.coeff + mkt.demand.coeff)
		equibX += mkt.supply.intercept - mkt.demand.intercept
		equibX /= (mkt.demand.coeff - mkt.supply.coeff)
		
		out = round(100 * (mkt.supply.coeff * (gafx + equibX) + mkt.supply.intercept))
		out /= 100 # get them pennies!
		
#		var easyPrint = {
#			'name': name,
#			'gafx': gafx,
#			'equibX': equibX,
#			'price': out,
#		}
#		print( easyPrint )
		return out

	
	# ##### ##### ##### #
	# MUTATOR FUNCTIONS
	# ##### ##### ##### #
	func add_route(route: EconRoute):
		# add check to prevent duplicate routes
		routes.push_back(route)

	# Shipment for outbound goods, Deliveries for inbound
	#func process_shipment(route: EconRoute, good_id: int, quantity: float):
	func process_shipment(quantity: float, _good_id: int = -1):
		assert(quantity >= 0, "process_shipment() requires positive quantity numbers")
		demand_export += quantity
		price = calculate_price()
	
	func process_delivery(quantity: float, _good_id: int = -1):
		assert(quantity >= 0, "process_delivery() requires positive quantity numbers")
		supply_import += quantity
		price = calculate_price()

# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
#		ECONROUTE CLASS DEFINITION
# _init(route_id, node_A, node_B, route_capacity)
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
# ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
class EconRoute:
	var id: int
	var side_A: EconNode
	var side_B: EconNode
	
	enum nodetype { HUB, POOL }

	# A - B = positive flow
	var capacity = {
		'total': 0.0,
		'taken': 0.0,
	}

	func _init(route_id:int, node_A: EconNode,
			node_B: EconNode, route_capacity: float):
		
		id = route_id
		capacity.total = route_capacity
		
		side_A = node_A
		side_A.add_route(self)
		
		side_B = node_B
		side_B.add_route(self)
	
	func available_capacity() -> float:
		return capacity.total - abs(capacity.taken)
	
	func is_full() -> bool:
		return abs(capacity.taken) >= capacity.total
	
	func get_other_side(source: EconNode) -> EconNode:
		return side_A if source == side_B else side_B

	func calculate_transport() -> Dictionary:
		var out: Dictionary = {}
		var source: EconNode = null	# node delivering goods
		var sink: EconNode = null	# node receiving goods
		var flow_sign: float = 0
		
		if side_A.goods_provided() > 0 and side_B.goods_requested() > 0:
			# then flow A->B
			source = side_A
			sink = side_B
			flow_sign = 1 # A->B is positive
		elif side_B.goods_provided() > 0 and side_A.goods_requested() > 0:
			# then flow B->A
			source = side_B
			sink = side_A
			flow_sign = -1 # B->A is negative
			
		if flow_sign != 0: # if any of the if's were hit
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
					'route_id': id,
					'good_id': -1,
					'AB_quantity': xfer_quantity * flow_sign,
				}
		
		return out
	
	func execute_trasport(AB_quantity: float, _good_id: float = -1):
		var source: EconNode = null	# node delivering goods
		var sink: EconNode = null	# node receiving goods
		var abs_qty: float = abs(AB_quantity)
		
		if AB_quantity > 0:	# deliver from A to B
			source = side_A
			sink = side_B
		else:	# deliver goods from B to A
			source = side_B
			sink = side_A
		
		source.process_shipment(abs_qty)
		sink.process_delivery(abs_qty)
		capacity.taken += AB_quantity
		
		var pStr = str("Route %.0f delivering %.1f from %s to %s. Cap(%.0f/%.0f)" %
				[id, abs_qty, source.name, sink.name, capacity.taken, capacity.total])
		print(pStr)
		pass








