require "/home/core/OverlayRPC/RoutingTable.rb"
require 'socket'
require 'ipaddr'
require 'thread'
include Socket::Constants
class Node
	def initialize(id, sequence, neighbors, routingTable)
		@id = id
		@sequence = sequence
		@neighbors = neighbors
		@routingTable = routingTable#RoutingTable.new(id)
	end

	def id
		@id
	end 	
	def routingTable
		@routingTable
	end

	def sequence
		@sequence
	end
	def setseq(src, info)
		if @sequence == nil
			@sequence = {}
		end
		@sequence[src] = info
	end
	def neighbors
		@neighbors
	end
	def setNeighbors(neighbors)
		@neighbors = neighbors
	end
	def setRT(rt)
		@routingTable = rt
	end
	def setSequence(seq)
		@sequence = seq
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
		rets = ""
		mysplit.each do |value|
			if value =~ /(\S+):(\d+)/ then
				if self.routingTable.getCost($1) != -1
					if small > $2.to_i
						small = $2.to_i
						rets = value.dup
					end
				end
			end
	
			
		end
		return rets
	end

	def ProcLSP(lsp_string)
#		@mutex.synchronize do
		if lsp_string =~ /LSP (\S+) (\S+) (\d+) "(.*)"/ then
			src = $1
			node = $2
			seq = $3
			payload = $4
		end
		if (node == self.id)
			puts("I'm myself, not sending")
			return
		end
		if self.sequence[src] == nil
		#	puts("not gonna ignore this")	
			setseq(src, seq.to_i)
			puts("#{sequence[src]}")#sequence(src) = seq.to_i
		#	puts("BANANANANANANANANANANANAN\n\n\n\n\n\n")
		elsif self.sequence[src].to_i >= seq.to_i
			puts("IGNORING 2")
			puts("IGNORING")
			return
		end
		setseq(src, seq.to_i)
		self.routingTable.associate(node, src)
		lowestKnown = self.LSPLowestCost(payload)
		lowestParse = lowestKnown.split(":")
		lowcost = lowestParse[1].to_i + self.routingTable.getCost(lowestParse[0])
		self.routingTable.update(src, lowcost)
#		puts("putting #{src} with cost #{lowcost} based on LSP from #{node}")
		self.routingTable.setPred(src, lowestParse[0])	
		payloadArr = payload.split
		payloadArr.each do |value|
			if value =~ /(\S+):(\d+)/ then
				cur = $1
				curcost = $2
				nextCost = lowcost + curcost.to_i
				if cur != lowestParse[0]
					self.routingTable.update(cur, nextCost)
#		puts("putting #{cur} with cost #{nextCost} based on LSP from #{node}")
					self.routingTable.setPred(cur, src)
				end
			end

		end
		self.neighbors.each { |key, value|
			sendLSP(key, lsp_string, src)
		}
		#sendThreads.each { |d|
		#	d.join
		#}
#	end
	end
	def packetize(str, maxlen)
		arr = []
		n = ((str.length.to_f / maxlen)).ceil
		0.step(n-1,1) { |i|
			arr[i] = str[i*maxlen,i+1*maxlen]
		}
		return arr
	end

	def sendLSP(key, str, src)
		if key == src
		 	#If the outgoing link is the same as incoming, ignore
			return
			
		end	
			realmsg = packetize(str, 50) 
			socket = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.sockaddr_in(6666, "#{key}")
			socket.connect(sockaddr)
			realmsg.each { |x|
				socket.write(x)
			}
			socket.close
	end
end 


#main
system("ruby /home/core/OverlayRPC/sendLSP.rb /tmp/t3.txt &")
weightfile = "/tmp/t1.txt"
INTERVAL = 10
MAXLEN = 90
$mutex = Mutex.new
lead = `hostname`
lead = lead.chomp!
$neighbors = {}
$sequence = 0
$sequenceHash = {}
$interfaces = []
$rt = RoutingTable.new(lead, $interfaces, $neighbors)
$myNode = Node.new(lead, $sequenceHash, $neighbors, $rt)
shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 

ipArr = shittyText.split('\n')
def poop()
	lead = `hostname`
	shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1` 
#	$neighbors = {}
#	sequence = 0
#	rt = RoutingTable.new("#{lead}")
	ipArr = shittyText.split('\n')
	ipArr[0].each { |x| 
		$myNode.routingTable.update(x.chomp!, 0)
		$myNode.routingTable.setPred(x, x)
	}	
	configFile = File.open(ARGV[0], 'r')
	
	while (line = configFile.gets())
		arr = line.split(",")
		if (ipArr[0].include?("#{arr[0]}")) then
			#puts("I have a neighbors, #{arr[1]} with cost #{arr[2]}")
			
			$neighbors["#{arr[1]}"] = arr[2].to_i
			$rt.update(arr[1], arr[2].to_i)
			$rt.setPred(arr[1], arr[0])
		else
		end
	end
	configFile.close
	$sequence += 1
	$neighbors.each { |key2, value2| 
		$myNode.routingTable.addNeighbor(key2)
	}
#	$myNode.setSequence($sequence)
	$myNode.setNeighbors($neighbors)
#	$myNode.setRT($rt)
#	myNode = Node.new($mutex, lead, $sequence, $neighbors, $rt)
	
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


#server.listen(20)
#server = Socket.new(AF_INET, SOCK_STREAM, 0)
#sockaddr = Socket.pack_sockaddr_in(6666, '0.0.0.0')
#server.bind(sockaddr)
#server.listen(40)
$myNode.routingTable.setInterfaces(ipArr[0])
poop()
threadDump = Thread.new do
	while true	
	sleep(30)
	$myNode.routingTable.dump
	end
end
while true
=begin
threadA = Thread.fork do
		if $sequence == 1
		sleep(15)
		end
		str = ""
		ipArr[0].each { |w| 
			str << "#{w.chomp!}:0 "
		}
		$myNode.neighbors.each{ |key, value|
			str << "#{key}:#{value} "
		}
		$myNode.routingTable.setInterfaces(ipArr[0])
		#$interfaces = $myNode.routingTable.setInterfaces(ipArr[0])
		str = str.chop
		ipArr[0].each { |key|
			key = key.chomp!
			lsp_string2 = "LSP #{key} #{lead} #{$sequence} \"#{str}\"\\n"
			realMsg = packetize(lsp_string2, MAXLEN)
			$myNode.neighbors.each { |key, value| 
				socket = Socket.new(AF_INET, SOCK_STREAM, 0)
				sockaddr = Socket.sockaddr_in(6666, "#{key}")
				socket.connect(sockaddr)
				realMsg.each { |x|
					socket.write(x)
				}
				
				socket.close
			}	
		}
#			$myNode.routingTable.dump
			#$myNode = poop()
			poop()
	end
=end
#threadA.join
#clisock = server.accept
#until server.closed?
#threadB = Thread.new(clisock = server.accept) { |client|

	#	$mutex.synchronize do
Thread.new(clisock = server.accept) { |client|
client = server.accept#,client_sockaddr = server.accept
		msg = ""

		fam, port, *addr = client.getpeername.unpack('nnC4')#getpeername.unpack('nnC4')#peeraddr
		remote_ip = addr.join('.')
	#	remote_ip = client_sockaddr
		( data = client.gets("\\n"))
		client.close
		puts("RECEIVED MSG from #{remote_ip} #{data}")	
		$myNode.procPacket(data)
}
	end

#	}
#threadB.join

#end



		





