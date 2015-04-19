require 'set'
require 'socket'
require 'ipaddr'
require 'thread'

class RoutingTable
	@interfaces = []
#	@association = {}
	def initialize(name, interfaces, neighbors)
		@my_mutex = Mutex.new
		@name = name
		@neighbors = Set.new
		@unvisited = Set.new
		@visited = Set.new
		@costHash = {}
		@predecessor = {}
		@interfaces = interfaces
	end
	
	def addNeighbor(neighbor)
		puts(neighbor)
		@neighbors.add(neighbor)
	end

	def neighbors
		@neighbors
	end
	def setInterfaces(arr)
		if @interfaces.empty?
		@interfaces = arr
		@association = {}
		@association[@name] = Set.new
		@association[@name].merge(arr)
		arr.each{ |x| 
			@costHash[x] = 0
			@predecessor[x] = x
		}
		else 
			@interfaces
		end
	end
	
	def association
		@association
	end
	
	def associate(node, ip)
	@my_mutex.synchronize do
		
		if @association[node] == nil
			@association[node] = Set.new
			@association[node].add?(ip)
		else
			@association[node].add?(ip)
		end
	end
	end	
	def deassociate(ip)
		@association.each { |key , value| 
			if value.include?(ip)
				return key
			end
		}
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

	def dump(filename)
		file = File.open(filename, 'a+')#/tmp/#{@name}.dump", 'a+')
		ret_ip = "#"
		ret_name = "?"
		@association.each { |key, value|
			small = 5000
			value.each { |ip| 
				cost = getCost(ip)
				if cost != -1
					if small > cost
						small = cost
						ret_name = key
						ret_ip = ip
					end
				end
			}	
		value = getCost(ret_ip)
		nexthop = nextHop(ret_ip)
		rnexthop = deassociate(nexthop)
		str = "#{@name},#{ret_name},#{value},#{rnexthop}"
		file.puts(str)
		}
		file.puts("/////////////////////////")
		file.close
	
=begin
		@costHash.each { |key, value|
			nexthop = nextHop(key)
			str = "#{@name},#{key},#{value},#{nexthop}"
			file.puts(str)
		}
		file.puts("++++++++++++++++++++++++++++")
		file.close
=end			
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
		if prev == nil
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
		retr = ""	
#			puts("CURRRRRRRR #{curr}")			
			destip = deassociate(dest)
			nexthopip = deassociate(curr)
			yes = association[nexthopip]
#			puts("+++++++++++++1")
			puts(yes.flatten.to_a)
#			puts("////////////")
			puts(neighbors.to_a)
			if (yes != nil)
				final_hop = yes.flatten.intersection(neighbors.flatten)
#				puts("2")
				if (final_hop.empty?)
					retr = curr
				else
				final_hop.each { |hol| 
					retr = hol
					puts(hol)
				}
				end	
			else
				retr = curr
			end
#			puts("3")
#			puts("found next hop to desitnation #{destip}:#{dest} -> #{nexthopip}:#{retr}")
		return retr
	end
end 
