require "/home/core/OverlayRPC/RoutingTable.rb"
require 'socket'
require 'ipaddr'
include Socket::Constants
class Node
	def initialize(id, sequence, neighbors, routingTable)
		@id = id
		@seqeuence = sequence
		@neighbors = neighbors
		@routingTable = RoutingTable.new(id)
	end
	
	def routingTable
		@routingTable
	end

	def neighbors
		@neighbors
	end

	def SendMsg(dest, msg)
		if (self.routingTable.getCost(dest) != -1)
			msgPacket = "SENDMSG "+ dest + " " + msg + "\\EOF"
			SendPacket(msgPacket, self.routingTable.nextHop(dest))
		else
			 puts("No path to specified host")
		end
	end

	def procPacket(pack_string)
		case pack_string
			when /LSP (.*)/
				procLSP(pack_string)
			when /SENDMSG (.*)/
				procSENDMSG(pack_string)
			else
				puts("Receieved an invalid message")
			end
	end
	
	def LSPLowestCost(string)
		split = string.split(" ")
		small = Float::INFINITY
		ret

		split.each do |value|
			if value =~ /(\S+):(\d+)/ then
				if self.RoutingTable.getCost(dest) != -1
					if small > $2.to_i
						small = $2.to_i
						ret = value
					end
				end
			end
			return ret
		end
	end

	def ProcLSP(lsp_string)
		if lsp_string =~ /LSP (\S+) (\d+) "(.*)"/ then
			src = $1
			seq = $2
			payload = $3
		end
	
		lowestKnown = LSPlowestCost(payload)
		lowestParse = lowestKnown.split(":")

		lowcost = lowestParse[1] + self.routingTable.getCost(lowestParse[0])
		self.routingTable.update(src, lowcost)
		
		payloadArr = payload.split(" ")
		payloadArr.each do |value|
			if value =~ /(\s+):(\d+)/ then
				cur = $1
				curcost = $2
				nextCost = lowcost + curcost
				self.routingTable.update(cur, nextCost)
			end

		end

		self.neighbors.each do |key|
			sendLSP(key, lsp_string)
		end
	end
end 


#main
weightfile = "/tmp/t1.txt"
INTERVAL = 10
MAXLEN = 20


id = `hostname`
id = id.chomp!
neighbors = {}
sequence = 0
rt = RoutingTable.new(id)

shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 

ipArr = shittyText.split('\n')
def poop()
	shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 
	neighbors = {}
	sequence = 0
	rt = RoutingTable.new("#{id}")
	ipArr = shittyText.split('\n')
	
	configFile = File.open(ARGV[0], 'r')
	
	while (line = configFile.gets())
		arr = line.split(",")
		if (ipArr[0].include?("#{arr[0]}")) then
			#puts("I have a neighbors, #{arr[1]} with cost #{arr[2]}")
			#neighbors["#{arr[0]}"] = arr[2].to_i
			neighbors["#{arr[1]}"] = arr[2].to_i
			rt.update(arr[1], arr[2].to_i)
			rt.setPred(arr[1], arr[0])
		else
		end
	end

	myNode = Node.new(id, sequence, neighbors, rt)
end

def packetize(str, maxlen)
	arr = []
	n = ((str.length.to_f / maxlen)).ceil
	0.step(n-1,1) { |i|
		arr[i] = str[i*maxlen,i+1*maxlen]
	}
	return arr
end


=begin
	Forked Process will sleep and then read the config file, then
	send LSP packets

	Main Process will act as a server and send messages as needed
=end
server = TCPServer.new(6666)
puts("HELLLOOOOOOOOOOOOOO #{ipArr[0]}")
#server = Socket.new(AF_INET, SOCK_STREAM, 0)
#sockaddr = Socket.sockaddr_in(6666, "localhost")
#server.bind(sockaddr)
#server.listen(6)
#puts(server) 
#while clisock = server.accept
#	server.listen

fork do
	while true
		sleep(5)
		myNode = poop()
		str = ""
		myNode.neighbors.each{ |key, value|
			#myNode.routingTable.costHash[key] = value;
			str << "#{key}:#{value} "
		}
		str = str.chop
		#lsp_string = "LSP #{id} #{sequence} \"#{str}\""
		ipArr[0].each { |key|
			key = key.chomp!
			lsp_string2 = "LSP #{key} #{sequence} \"#{str}\"\n"
			#puts(lsp_string2)
			realMsg = packetize(lsp_string2, MAXLEN)
			realMsg.each { |y|
			#	puts "RealMSG content " + y
			}
			#puts("---------------------");
			#puts (realMsg)
			myNode.neighbors.each { |key, value| 
				socket = Socket.new(AF_INET, SOCK_STREAM, 0)
				#realkey = key.dup
				#realkey = realkey.chomp!
				puts(key)
				puts("REALKEY = #{key}")
				sockaddr = Socket.sockaddr_in(6666, "#{key}")
				puts("establishing connection")
				socket.connect(sockaddr)
				puts("CONNECTION ESTABLISHED")
				realMsg.each { |x|
					#puts("writing #{x}")
					#puts("writing #{x} to #{key}") 
					#puts("writing to #{realkey}")
					socket.puts(x)
				}
				socket.close
				puts("closing socket")
			}	
		}
			sequence = sequence + 1
			sleep(INTERVAL)
	end
end
puts "Sanity Check 1"
puts "Sanity Check 2"
while true
clisock = server.accept
#until server.closed?
	Thread.new(clisock) { |client|
		msg = ""
		remote_ip = clisock.peeraddr


		#while ( (data = clisock.recvfrom(MAXLEN)[0].chomp)[-1] != "\n")
		while ( !(client.closed?) )
			data = client.gets
			msg << data
			#puts("#{data}")
			#puts("Sanity Check Reading")
			if client.closed? 
				data = client.gets
				client.close
				msg << data
			end
		end
		client.close
		puts("----------------------")
		puts (msg)
		puts("RECEIVED MSG from #{remote_ip} #{msg}")	
		myNode.procPacket(msg)
	}

end


		





