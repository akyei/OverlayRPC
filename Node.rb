require 'set'
require 'lsp'
require 'socket'


class Graph
    Vertex = Struct.new(:name, :neighbors, :dist, :prev)


class RoutingTable
    @unvisited = Set.new
    @visited = Set.new
    @costHash = {}
    @predecessor = {}
    

    def initialize()
    end

    def dijkstra(source)
        return if 
    end
    def findShortestPaths()
        while not (@visted.empty?)


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
            # Construct packet string from design document
            msgPacket = "SENDMSG"
            
    end
    
    def ProcLSP(lsp_packet)
        # Assume lsp "A:3 B:4 ". With this information we may discover new neighbors
        # First, compare sequence number of lsp to this.sequence for relevance.
        # If lsp.sequence > this.sequence, for each lsp "pair", process Dijkstra's
        # Update neighbors from the Routing Table's keys.
        # Fishy buisness: Make sure not to send 0 self-cost pairs.
        
        src
        seq
        payload
        payloadArr = Array.new
        neighbors = {}
        newNodes = Set.new
        
        lsp_payload = lsp_packet.payload
        if lsp_payload =~ (LSP (\s+) (\d+) (\d+) "((\s+:\d+)+)") then
            match $1 with src
            match $2 with seq
            match $3 with payload
        end
        
        if self.sequence["src"] > seq
            return
        end
        
        self.sequence["src"] = seq
        
        payloadArr = payload.split(" ")
        
        payloadArr.each do |value|
            if value =~ ((\s+):(\d+)) then
                neighbors[$1] = $2
        end
        
        
        
        
    
    end
    
end






