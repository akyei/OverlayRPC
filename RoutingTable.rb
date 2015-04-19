require 'set'
require 'socket'
require 'ipaddr'


class RoutingTable
	@interfaces = []
	def initialize(name, interfaces)
		@name = name
		@unvisited = Set.new
		@visited = Set.new
		@costHash = {}
		@predecessor = {}
		@interfaces = interfaces
	end
	
	def setInterfaces(arr)
		@interfaces = arr
	end
	def interfaces
		@interfaces
	end
	def setPred(src, pred)
		@predecessor[src] = pred
	end
	
	def name
		@name
	end

	def dump
		file = File.open("/tmp/#{@name}.dump", 'a+')
		@costHash.each { |key, value|
			nexthop = nextHop(key)
			str = "#{@name},#{key},#{value},#{nexthop}"
			file.puts(str)
		}
		file.puts("++++++++++++++++++++++++++++")
		file.close			
	end

	def costHash
		@costHash
	end

	def predecessor
		@predecessor
	end	
	def getCost(node)
		if (costHash[node] != nil)
			return costHash[node]
		else
			return -1
		end
	end
	
	def update(node, cost)
		if @interfaces.include?(node)
			@costHash[node] = 0
		else
			if @costHash[node] == nil
				@costHash[node] = cost
			elsif @costHash[node] >= cost
				@costHash[node] = cost
			end
		end
	end

	def Dijkstra(source)
		return
	end
	
	def findShortestPaths()
		while not (@visted.empty?)
		end
	end

	def nextHop(dest)
		prev = predecessor[dest]
		curr = dest
		#prev = dest
		#curr = predecessor[dest]
		if curr == nil
#			puts("couldn't find next hop")
			return "?"
		end
		#while  not (self.interfaces.include?(curr))#name != curr)
		while not ( curr == predecessor[curr])
	#		puts(self.interfaces)
	#		puts(curr)
		#	puts("I'M LIKE A BIRD!!!")	
			prev = curr
			curr = predecessor[curr]
		end
#			puts("found next hop #{prev}")
		return curr
	end
end 
