require 'set'
require 'socket'
require 'ipaddr'
class Graph
    Vertex = Struct.new(:name, :neighbors, :dist, :prev)
end

class RoutingTable
    @name 
    @unvisited = Set.new
    @visited = Set.new
    @costHash = {}
    @predecessor = {}
    

    def initialize()
    end

    def dijkstra(source)
        return 
    end
    def findShortestPaths()
        while not (@visted.empty?)


        end
    end
    
    def nextHop(dest)
        prev
        curr = predecessor["dest"]
        while (self.name != curr)
            prev = curr
    	end

   end
end
class Node

    def initialize(id, sequence, neighbors, routingTable)
        @id
        @sequence 
        @neighbors = {}
        @routingTable = RoutingTable.new
    end
    
    def SendMsg(dest, msg)
        # First, determine if the message has somewhere to go - we need to look up
        # the routing table to see if a path exists to dest.
        # If this is the case, we'll construct a SENDMSG packet
        
        # Proposed function that returns the cost if NODE has routing table entry
        # -1 returned from this function if dest isn't in the routing table.
        if (@routingTable.getCost(dest) != -1)
            # Construct packet string from design document -> need clarification on how to send EOF
            msgPacket = "SENDMSG " + dest + " " + msg + "EOF"
            # push this string to the next hop -> need network code and to find next hop from Dijkstra
            # SendPacket placeholder/function to send a string across the network (string, nextHop)
            # @routingTable.nextHop(dest) returns the neighbor of self needed to send message
            SendPacket(msgPacket, @routingTable.nextHop(dest))
            # Ideally will wait here for a response from the dest to see if resending is an issue
        end 
    end
    
    def Ping(dest, numPings, delay)
        # Initial idea here is to send a Req packet, and wait for an Ack response to see if line is live
        # Message format from design document states "PING [DEST] [NUM] [DELAY]EOF.  I believe these
        # are actually parameters for the function rather than being part of the message.
        if (@routingTable.getCost(dest) != -1)
            pingPacket = "PING " + 
            count = 0
            while (count != numPings)
            # THIS ISN'T THE TIME NOR PLACE FOR THIS KIND OF INSOLENCE
            end
        end
                
    end
    
    def procPacket(pack_string)
        if pack_string =~ /(\s+) /
            if $1 == "LSP"
                ProcLSP(pack_string)
            end
        end
    end
    
    def LSPlowestCost(string)
        split = string.split(" ")
        small = Float::INFINITY
        ret
        
        split.each do |value|
            if value =~ /(\s+):(\d+)/ then
                if self.RoutingTable["#{$1}"] != nil 
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
=begin
      1) Begin by taking note of the source of the LSP packet - this will become the the predecesor of all of src's neighbors
      2) Search for the lowest cost amoung the LSP packet that is also a neighbor of THIS node. i.e: If A's neighbor is B, and B is
      the lowest cost neighbor of Src, then take note of this as a variable
      3) Add src of LSP packet to this.routing table using the node from step two
      4) Set the cost of src's cost equal to the cost in the LSP packet + the cost of the node from THIS to the node from step 2
      5) Now, process all remaining nodes left in LSP packet, using src as its predecessor
      6) Push LSP to all of THIS neighbors (sequence number will stop inifinite propogationis akis m ini
=end
        
        if lsp_string =~ /LSP (\S+) (\d+) "(.*)"/ then
            src = $1# match $1 with src
            seq = $2#match $2 with seq
            payload = $3 #match $3 with payload
        end
        
        
        
    lowestKnown = LSPlowestCost(payload)
    lowestParse = lowestKnown.split(":")
    # Assume function that gets the cost of a given node from a routing table
    lowCost = lowestParse[1] + @routingTable.getCost(lowestParse[0])
    # Assume function that updates routing table entry. If entry exists, update cost, otherwise ADD value with cost
    @routingTable.update(src, lowCost)
    
    #Parsing the payload into an array of id:cost strings
    payloadArr = payload.split(" ")
        
    #Parsing each element id:cost into a new neighbors hash
    payloadArr.each do |value|
    if value =~ /(\s+):(\d+)/ then
        cur = $1 #match $1 with cur
        curCost = $2 #match $2 with curCost
        nextCost = lowCost + curCost
        @routingTable.update(cur, nextCost)
    end
    end
    @neighbors.each do |cur|
        sendLSP(lsp_string)
	end
	end
end
    
id = `hostname`
neighbors = {}
sequence = 0
rt = RoutingTable.new()        
#ipArr = Socket.getifaddrs.map { |i| i.addr.ip_address if i.addr.ipv4? }.compact

shittyText = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1`
#puts("#{shittyText}")
ipArr = shittyText.split('\n')
#ipArr[0].chop!
#ipArr = Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET).map{ |x| x[3] }
#ipArr = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]

#puts("#{ipArr}")

configFile = File.open(ARGV[0], 'r')

while (line = configFile.gets())
    #puts("#{line}") 
    arr = line.split(',')
	#puts("IP ADD 1 #{ipArr[0]} IP ADD 2 #{ipArr[1]} QUESTION IP #{arr[0]}")
	if ( ipArr[0].include?("#{arr[0]}")) then #[0])) then
        puts("I have a neighbor, #{arr[1]} with cost #{arr[2]}")
   	neighbors["#{arr[0]}"] = arr[2].to_i  
	else 
	end
end  
    
thisNode = Node.new(id, sequence, neighbors, rt)
        



