require 'set'
require 'socket'
require 'ipaddr'


class RoutingTable
	def initialize(name)
		@name = name
		@unvisited = Set.new
		@visited = Set.new
		@costHash = {}
		@predecessor = {}
	end
	
	def setPred(src, pred)
		@predecessor[src] = pred
	end
	
	def name
		@name
	end

	def costHash
		@costHash
	end
	
	def getCost(node)
		if (costHash[node] != nil)
			return costHash[node]
		else
			return -1
		end
	end
	
	def update(node, cost)
		@costHash[node] = cost
	end

	def Dijkstra(source)
		return
	end
	
	def findShortestPaths()
		while not (@visted.empty?)
		end
	end

	def nextHop(dest)
		prev
		curr = predecessor[dest]
		while (self.name != curr)
			prev = curr
		end
	end
end 
