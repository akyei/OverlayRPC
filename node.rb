require "/home/core/OverlayRPC/RoutingTable.rb"
require 'socket'
require 'ipaddr'
include Socket::Constants
class Node
	def initialize(id, sequence, neighbors, routingTable)
		@id = id
		@seqeuence = sequence
		@neighbors = neighbors
		@routingTable = routingTable#RoutingTable.new(id)
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
				#puts("Processing an LSP")
				ProcLSP(pack_string)
			when /SENDMSG (.*)/
				procSENDMSG(pack_string)
			else
				puts("Receieved an invalid message")
			end
	end
	
	def LSPLowestCost(string)
		mysplit = string.split(" ")
		small = 5000
		ret = nil
		puts("sanitybaby")
		mysplit.each do |value|
			if value =~ /(\S+):(\d+)/ then
			#	puts("DOLLAR SIGN: "+$1)
				if (self.routingTable.getCost($1) == 0)
			#	puts(self.routingTable.getCost($1))
				
				elsif self.routingTable.getCost($1) != -1
				puts("sanityadult")
					if small > $2.to_i
						small = $2.to_i
						ret = value
					end
				end
			end
		
			
		end
		return ret
	end

	def ProcLSP(lsp_string)
		puts("sanity")	
		if lsp_string =~ /LSP (\S+) (\d+) "(.*)"/ then
			src = $1
			seq = $2
			payload = $3
		end
		puts(payload)
		lowestKnown = self.LSPLowestCost(payload)
		puts("LOWESTKNOWN: #{lowestKnown}")
		lowestParse = lowestKnown.split(":")
	#	puts("its cool im sane")
		puts("LOWEST PARSE: #{lowestParse[1]} #{lowestParse[0]}")
		lowcost = lowestParse[1].to_i + self.routingTable.getCost(lowestParse[0].chomp)
		puts("sanity 3")
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

	def sendLSP(key, str)
		puts("At least i got this far")
	end
end 


#main
weightfile = "/tmp/t1.txt"
INTERVAL = 10
MAXLEN = 90


lead = `hostname`
lead = lead.chomp!
neighbors = {}
$sequence = 0
$rt = RoutingTable.new(lead)

shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 

ipArr = shittyText.split('\n')
def poop()
	lead = `hostname`
	shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 
	neighbors = {}
#	sequence = 0
#	rt = RoutingTable.new("#{lead}")
	ipArr = shittyText.split('\n')
	ipArr[0].each { |x| 
		#puts("THIS IS MY COST #{x}")
		$rt.update(x.chomp!, 0)
		#$rt.costHash[x] = 50
		#puts($rt.getCost(x))
		#puts($rt.getCost("10.0.0.21"))
		#puts($rt.getCost("10.0.0.20"))
	}	
	configFile = File.open(ARGV[0], 'r')
	
	while (line = configFile.gets())
		arr = line.split(",")
		if (ipArr[0].include?("#{arr[0]}")) then
			#puts("I have a neighbors, #{arr[1]} with cost #{arr[2]}")
			#neighbors["#{arr[0]}"] = arr[2].to_i
			neighbors["#{arr[1]}"] = arr[2].to_i
			$rt.update(arr[1], arr[2].to_i)
			#puts ("COST METRIC" + $rt.getCost(arr[1]).to_s)
			$rt.setPred(arr[1], arr[0])
		else
		end
	end
	configFile.close
	$sequence += 1
	myNode = Node.new(lead, $sequence, neighbors, $rt)
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
server = TCPServer.new('0.0.0.0', 6666)
#puts("HELLLOOOOOOOOOOOOOO #{ipArr[0]}")
#server = Socket.new(AF_INET, SOCK_STREAM, 0)
#sockaddr = Socket.sockaddr_in(6666, "localhost")
#server.bind(sockaddr)
#server.listen(6)
#puts(server) 
#while clisock = server.accept
#	server.listen
myNode = poop()
fork do
	while true
		sleep(5)
	#	myNode = poop()
		str = ""
		ipArr[0].each { |w| 
			str << "#{w.chomp!}:0 "
		}
		myNode.neighbors.each{ |key, value|
			#myNode.routingTable.costHash[key] = value;
			str << "#{key}:#{value} "
		}
		str = str.chop
		#lsp_string = "LSP #{id} #{sequence} \"#{str}\""
		ipArr[0].each { |key|
			key = key.chomp!
			lsp_string2 = "LSP #{key} #{$sequence} \"#{str}\"\\n"
			puts(lsp_string2)
			#puts(lsp_string2)
			realMsg = packetize(lsp_string2, MAXLEN)
			realMsg.each { |y|
				#puts "RealMSG content " + y
			}
			#puts("---------------------");
			#puts (realMsg)
			myNode.neighbors.each { |key, value| 
				socket = Socket.new(AF_INET, SOCK_STREAM, 0)
				#realkey = key.dup
				#realkey = realkey.chomp!
				#puts(key)
				#puts("REALKEY = #{key}")
				sockaddr = Socket.sockaddr_in(6666, "#{key}")
				#puts("establishing connection")
				socket.connect(sockaddr)
				#puts("CONNECTION ESTABLISHED")
				realMsg.each { |x|
					#puts("writing #{x}")
					#puts("writing #{x} to #{key}") 
					#puts("writing to #{realkey}")
					socket.write(x)
					#puts("wrote #{x}")
				}
			#	socket.close
			#	puts("closing socket")
			#	while ((text = socket.recv(MAXLEN)) != "OK")
			#		puts(text)
			#	end
				
				socket.close
			}	
		}
			#sequence = sequence + 1
			sleep(INTERVAL)
			myNode = poop()
	end
end
while true
#clisock = server.accept
#until server.closed?
	Thread.new(clisock = server.accept) { |client|
		msg = ""
		remote_ip = client.peeraddr


		#while ( (data = clisock.recvfrom(MAXLEN)[0].chomp)[-1] != "\n")
		#while (msg[-1] != "\v")
		#while ( !(client.closed?) )
#		while ( data = client.gets("\\n"))
		( data = client.gets("\\n"))
#			puts ("SERVER: #{data}")
		#	data = client.gets
			#msg << data.chomp!
#			puts("sanity")	#puts("#{data}")
			#puts("Sanity Check Reading")
			#if client.closed? 
		#		data = client.gets
		#		client.close
		#		msg << data
		#	end
#		end
		#client.close
		
		client.close
#		puts("----------------------")
		#puts (msg)
#		puts("RECEIVED MSG from #{remote_ip} #{data}")	
		myNode.procPacket(data)
	}

end


		





