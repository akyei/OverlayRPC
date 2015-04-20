#!/usr/bin/ruby
INFINITY = 1.0/0.0
require 'thread'
require 'socket'
require 'ipaddr'
require 'optparse'
include Sockets::Constants

options = {:weightfile => nil, :routefile => nil, :dumpinterval => nil, :routeinterval => nil, :length => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: graph.rb -w [filename] -r [filename] -d [dump interval] -rt [Protocol Interval] -ml [Max packet length]"
	opts.on('-w' '--weightfile weightfile', 'Weight Input File') do |weight|
		options[:weightfile] = weight
	end
	opts.on('-r' '--routefile routefile', 'Route Output File') do |route|
		options[:routefile] = route
	end
	opts.on('-d' '--dump interval(seconds)', Fixnum, 'How often the routing information is sent to a text file') do |delay|
		options[:dumpinterval] = delay
	end
	opts.on('-rt' '--route-time time(seconds)', Fixnum, 'How often the routing protocol is run') do |rtime|
		options[:routeinterval] = rtime
	end
	opts.on('-ml' '--maxlength length(bytes)', Fixnum, 'Maximum Packet Length in bytes') do |length|
		options[:maxlength] = length
	end
	opts.on('-h' '--help', 'Display Help') do 
		puts opts
		exit
	end
end
parser.parse!
if options[:weightfile] == nil
	puts("Specify a weightfile with -w")
	exit
elsif options[:routefile] == nil
	puts("Specify a file to dump routing tables with -r")
	exit
elsif options[:dumpinterval] == nil
	puts("Routing Table dump interval not specified, defaulting to 15 seconds")
	options[:dumpinterval] = 15
elsif options[:routeinterval] == nil
	puts("Route Calculation interval not specified, defaulting to 10 seconds")
	options[:routeinterval] = 10
elsif options[:maxlength] == nil
	puts("Maximum Packet Length not specified, defaulting to 20 bytes")
	options[:maxlength] = 20
end

$hostname = `hostname`
$associations = {}
$hostname = $hostname.chomp!
ip_addresses = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1`
$interfaces = ip_addresses.split('\n')[0]
$mutex = Mutex.new
$sequence = {}
$maxlen = options[:maxlength]
$routeinterval = options[:routeinterval]
$dumpinterval = options[:routeinterval]
$weightfile = options[:weightfile]
$routefile = options[:routefile]
class Graph

Vertex = Struct.new(:name, :neighbors, :dist, :prev)

def initialize(graph)
	@vertices = Hash.new { |h,k| h[k] = Vertex.new(k, [], [INFINITY, 0])}
	@edges = {}
	graph.each do |(v1, v2, dist)|
		@vertices[v1].neighbors << v2
		@vertices[v2].neighbors << v1
		@edges[[v1, v2]] = @edges[[v2, v1]] = dist[0]
	end
	@dijkstra_source = nil
end

def vertices
	@vertices
end

def addEdge(edge)
	edge.each do |(v1, v2, dist)|
		@vertices[v1].neighbors << v2
		@vertices[v2].neighbors << v1
		@edges[[v1,v2]] = @edges[[v2, v1]] = dist[0]
	end
end

def dijkstra(source)
	return if @dijkstra_source == source
	q = @vertices.values
	q.each do |v|
		v.dist[0] = INFINITY
		v.prev = nil
	end
	@vertices[source].dist[0] = 0
	until q.empty?
		u = q.min_by {|vertex| vertex.dist[0]}
		break if u.dist[0] == INFINITY
		q.delete(u)
		u.neighbors.each do |v|
			vv = @vertices[v]
			if q.include?(vv)
				alt = u.dist[0] + @edges[[u.name, v]]
				if alt < vv.dist[0]
					vv.dist[0] = alt
					vv.prev = u.name
				end
			end
		end
	end
	@dijkstra_source = source
end

def shortest_path(source, target)
	dijkstra(source)
	path = []
	u = target
	while u
		path.unshift(u)
		u = @vertices[u].prev
	end
	return path, @vertices[target].dist[0]
end

def to_s
	"#<%s vertices=%p edges=%p>" % [self.class.name, @vertices.values, @edges]
end
end
#main
=begin
if (ARGV[0] == nil)
	puts("YOU MUST SPECIFY A CONFIG FILE")
	exit
end
=end
#puts($interfaces)

$graph = Graph.new
$interfaces.each do |key|
	$interfaces.each do |key2|
		if key2 != key
			$graph.addEdge([:"#{key}", :"#{key2}", [0,0]])
		end
	end
end
$graph.dijkstra(:"#{$interfaces[0]}")
=begin
g = Graph.new([	[:a, :b, [7,2]],
		[:a, :c, [9,3]],
                [:a, :f, [14,4]],
                [:b, :c, [10,2]],
                [:b, :d, [15,3]],
                [:c, :d, [11,4]],
                [:c, :f, [2,4]],
                [:d, :e, [6,6]],
                [:e, :f, [9,8]],
              ])
start, stop = :a, :e
puts(g)
path, dist = g.shortest_path(start, stop)
puts("shortest path from #{start} to #{stop} has cost #{dist}")
puts(path.join(" -> "))
g.addEdge([[:a, :c, [6, 4]]])
puts(g)
=end


def packetize(str)
	arr = []
	n = ((str.length.to_f / $maxlen)).ceil
	0.step(n-1, 1) { |i|
		arr[i] = str[i*$maxlen, (i+1)*$maxlen]
	}
	return arr
end
def associate(node, src)
	if $associations[node] == nil
		$associations[node] = Set.new
		$associations[node].add(src)
	else
		$associations[node].add(src)
		$associations.flatten!
	end
end
def sendLSP(lsp_string, source)
	$neighbors.each do |key|
		if key == source
			next
		end
		realmsg = packetize(str, MAXLEN)
		socket = Socket.new(AF_INET, SOCK_STREAM, 0)
		sockaddr = Socket.sockaddr_in(6666, "#{key}")
		socket.connect(sockaddr)
		realmsg.each{ |x|
			socket.write(x)
		}
		socket.close
	end
end
def procLSP(lsp_string, source)
	if lsp_string =~ /LSP (\S+) (\S+) (\d+) "(.*)"/ then
		src = $1
		node = $2
		seq = $3
		payload = $4
	end
	if (node == $hostname)
		#The LSP was from this node, don't send again
		return nil
	elsif $sequence[src] == nil
		#No associated sequence number from this link
		$sequence[src] = seq.to_i
	elsif $sequence[src] >= seq.to_i
		#Already received a more recent LSP from this link
		return nil
	end
	$sequence[src] = seq.to_i
	associate(node, src)
	syms = []
	info = payload.split(" ")
	info.each do |link|
		parse = link.split(":")
		syms << [:"#{src}", :"#{parse[0]}", [parse[1].to_i, seq.to_i]]
	end
	$graph.addEdge(syms)
	sendLSP(lsp_string, source)
	true
end
def procPacket(pack_string, source)
	case pack_string
		when /LSP (.*)/
			$mutex.synchronize do
				procLSP(pack_string, source)
			end
		when /SENDMSG (.*)/
			procSENDMSG(pack_string)
		else
			puts("Received an invalid message")
		end
end
def dump(filename)
$mutex.synchronize do
	file = File.open(filename, 'a+')
	ret_ip = "#"
	ret_name = "?"
	source = $interfaces[0]
	start = :"#{source}"
	$graph.dijkstra(start)
	$graph.vertices.each { |key, value|
		path, dist = $graph.shortest_path(start, key)
		if not $interfaces.include(key)
			while $interfaces.include?(path[0])
				path.shift
			end
		end
		file.puts("#{$hostname},#{key},#{dist},#{path[0]},#{$graph.vertices[key].dist[1]}")
	}
	file.puts("++++++++++++++++++++++++++++++++++++++++++++++++")
	file.close
end
end
	
 
threadA = Thread.new do
	loop{
	sleep($routeinterval)
	$mutex.synchronize do
		$graph.dijkstra($interfaces[0])
	end
	}
end
threadB = Thread.new do
	loop { 
		sleep($dumpinterval)
		dump($routefile)
	}
end
#=begin
server = TCPServer.new('0.0.0.0', 6666)
loop {
	Thread.start(server.accept) do |client|
		msg = ""
		fam, port, *addr = client.getpeername.unpack('nnC4')
		remote_ip = addr.join('.')
		data = client.gets("\\n")
		client.close
		if procPacket(data, remote_ip)
			puts("RECEIVED MSG from #{remote_ip} #{data}")
		end
	end
}
#=end		
