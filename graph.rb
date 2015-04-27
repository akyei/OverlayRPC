#!/usr/bin/ruby
INFINITY = 1.0/0.0
require 'thread'
require 'socket'
require 'ipaddr'
require 'optparse'
require 'set'
require 'openssl'
include Socket::Constants

options = {:weightfile => nil, :routefile => nil, :dumpinterval => nil, :routeinterval => nil, :length => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: graph.rb -w [filename] -r [filename] -d [dump interval] -q [Protocol Interval] -m  [Max packet length]"
	opts.on('-w', '--weightfile weightfile', 'Weight Input File') do |weight|
		options[:weightfile] = weight
	end
	opts.on('-r', '--routefile routefile', 'Route Output File') do |route|
		options[:routefile] = route
	end
	opts.on('-d', '--dump interval(seconds)', 'How often the routing information is sent to a text file') do |delay|
		options[:dumpinterval] = delay.to_i
	end
	opts.on('-q', '--routetime time(seconds)', Float, 'How often the routing protocol is run') do |rime|
		options[:routeinterval] = rime.to_i
	end
	opts.on('-m', '--maxlength length(bytes)', Float, 'Maximum Packet Length in bytes') do |length|
#		puts("here")
		options[:maxlength] = length.to_i
	end
	opts.on('-h', '--help', 'Display Help') do 
		puts opts
		exit
	end
end
parser.parse!
if options[:weightfile] == nil
	puts("Specify a weightfile with -w")
	exit
end
if options[:routefile] == nil
	puts("Specify a file to dump routing tables with -rt")
	exit
end
if options[:dumpinterval] == nil
	puts("Routing Table dump interval not specified, defaulting to 15 seconds")
	options[:dumpinterval] = 15
end
if options[:routeinterval] == nil
	puts("Route Calculation interval not specified, defaulting to 10 seconds")
	options[:routeinterval] = 10
end
if options[:maxlength] == nil
	puts("Maximum Packet Length not specified, defaulting to 20 bytes")
	options[:maxlength] = 20
end
$neighbors = {}
$hostname = `hostname`
$associations = {}
$hostname = $hostname.chomp
ip_addresses = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1`
$interfaces = ip_addresses.split("\n")
$mutex = Mutex.new
$sequence = {}
$maxlen = options[:maxlength]
$routeinterval = options[:routeinterval]
$dumpinterval = options[:dumpinterval]
$weightfile = options[:weightfile]
$routefile = options[:routefile]
$routefile << "#{$hostname}.dump"
class Graph

Vertex = Struct.new(:name, :neighbors, :dist, :prev)

def initialize(graph)
	@vertices = Hash.new { |h,k| h[k] = Vertex.new(k, [], [0, 0])}
	@edges = {}
	graph.each do |(v1, v2, dist)|
		if not @vertices[v1].neighbors.include?(v2)
			@vertices[v1].neighbors << v2
		end
		if not @vertices[v2].neighbors.include?(v1)
			@vertices[v2].neighbors << v1
		end
		@edges[[v1, v2]] = @edges[[v2, v1]] = dist[0]
	end
	@dijkstra_source = nil
end

def vertices
	@vertices
end

def addEdge(edge)
	edge.each do |(v1, v2, dist)|
		if not @vertices[v1].neighbors.include?(v2)
			@vertices[v1].neighbors << v2
		end
		if not @vertices[v2].neighbors.include?(v1)
			@vertices[v2].neighbors << v1
		end
		@vertices[v2].dist = [nil, dist[1]]
		@vertices[v1].dist= [nil, dist[1]]
		#@vertices[v2].dist = dist
		#@vertices[v1].dist= dist
		@edges[[v1,v2]] = @edges[[v2, v1]] = dist[0]
	end
end

def reset
	@dijkstra_source = nil
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

#$graph = Graph.new
def associate(node, src)
	#puts("#{node} #{src}")
	if $associations[node] == nil
		$associations[node] = Set.new
		$associations[node].add(src)
	else
		$associations[node].add(src)
		$associations[node].flatten!
	end
end
initEdges = []
$interfaces.each do |key|
	$interfaces.each do |key2|
=begin
if $interfaces.length() == 1
			initEdges << [:"#{key.chomp}", :"#{key2.chomp}", [INFINITY,0]]
		end
=end
		if key2 != key
		#	puts("Hey baby, I lvoe you")
			#puts("Key 1 #{key} Key 2: #{key2}")
			initEdges << [:"#{key.chomp}".to_sym, :"#{key2.chomp}".to_sym, [0,0]]
			#$graph.addEdge([:"#{key}", :"#{key2}", [0,0]])
			associate($hostname, key2)
		end
	end
end
#puts(initEdges)
$graph = Graph.new(initEdges)
configFile = File.open($weightfile, 'r')
while line=configFile.gets()
	arr = line.split(",")
	if $interfaces.include?("#{arr[0]}")
		#puts("I have a neighbor #{arr[1]} with cost #{arr[2]}")
		$neighbors["#{arr[1]}"] = arr[2].to_i
	else
	end
end
configFile.close
#$graph.dijkstra(:"#{$interfaces[0].chomp}")
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
=begin
	arr = []
	n = ((str.length.to_f / $maxlen)).ceil
	0.step(n-1, 1) { |i|
		arr[i] = str[i*$maxlen, (i+1)*$maxlen]
	}
	return arr
=end
	arr = str.chars.each_slice($maxlen).map(&:join)
	return arr
end
def sendLSP(lsp_string, source, node)
	if (node == $hostname)
		return
	end
	$neighbors.each do |key, value|
		if key == source
			next
		end
		#puts("sending to #{key}")
		realmsg = packetize(lsp_string)
		socket = Socket.new(AF_INET, SOCK_STREAM, 0)
		sockaddr = Socket.sockaddr_in(6666, "#{key}")
		socket.connect(sockaddr)
		realmsg.each{ |x|
			socket.write(x)
		}
		socket.close
	end
	#puts()
end
def procLSP(lsp_string, source)
	$mutex.synchronize do
	if lsp_string =~ /LSP (\S+) (\S+) (\d+) "(.*)"/ then
		src = $1
		node = $2
		seq = $3
		payload = $4
	end
#	if (node == $hostname)
		#The LSP was from this node, don't send again
#		return nil
	if $sequence[src] == nil
#		puts("encountering first sequence number")#No associated sequence number from this link
		$sequence[src] = seq.to_i
	elsif $sequence[src] >= seq.to_i
		#Already received a more recent LSP from this link
		return 
	end
#	puts("found a new sequence number #{$seqeunce}")
	$sequence[src] = seq.to_i
	associate(node, src)
	syms = []
#	puts("Syms class: #{syms.class}")
	info = payload.split(" ")
	info.each do |link|
		parse = link.split(":")
		if src == parse[0]
		elsif not parse[0] =~ /[\d]+\.[\d]+\.[\d]+\.[\d]+/
			next
		else
#			if $interfaces.include?(parse[0])
#				if $neighbors.has_key?(src)
#					syms << [:"#{src}".to_sym, :"#{parse[0]}".to_sym, [parse[1].to_i, seq.to_i]]
#					puts("Adding Edge because #{src} is a neighbor")
#				end
#			else 
			syms << [:"#{src}".to_sym, :"#{parse[0]}".to_sym, [parse[1].to_i, seq.to_i]]
#			end
		end
	#	puts("Syms class: #{syms.class}")
	#	puts("SYMS: #{syms[0]} #{syms[1]} #{syms[2]}")
	end
	$graph.addEdge(syms)
	#puts("about to send lsp to neighbors")
	sendLSP(lsp_string, source, node)
	return true
end
end
def procPING(pack_string, inc_socket)
#	puts(pack_string)	
	fam, port, *addr = inc_socket.getpeername.unpack('nnC4')
	client = addr.join('.')
	
	if pack_string =~ /PING (\S+) (\d+) (\d+)/
		destination = $1
		numpings = $2
		delay = $3
	end
	if destination =~ /[\d]+\.[\d]+\.[\d]+\.[\d]+/
		nexthop = findNextHopIP(destination)
	else
		nexthop = findNextHop(destination)
	end
	if (nexthop == nil)
	#	puts("AT my destination, waiting")
		while true
			data = inc_socket.gets("\\n") 
			if data =~ /END/
				inc_socket.close
				break
			elsif data =~ /ping/
	#			puts("writing response")
				inc_socket.write("RESPONSE\\n")
			end
		end
	else
		sock = Socket.new(AF_INET, SOCK_STREAM, 0)
		sockaddr = Socket.pack_sockaddr_in(6666, "#{nexthop}")
		sock.connect(sockaddr)
		realmsg = packetize(pack_string)
		realmsg.each { |x|
			sock.write(x)
		}
	#	puts("GOing to read from socket to blast pingus") 
		while true
	#		puts("trying to read from socket")
			data = inc_socket.gets("\\n")
	#		puts("read data = #{data}")
			realmsg = packetize(data)
			realmsg.each { |x|
				sock.write(x)
			}
			resp_data = sock.gets("\\n")
			inc_socket.write(resp_data)
			if data =~ /END/
				break
			end
		end
		sock.close
	end
end
def procTRACEROUTE(pack_string, inc_socket)
	fam, port, *addr = inc_socket.getpeername.unpack('nnC4')
	client = addr.join('.')
	if pack_string =~ /TRACEROUTE (\S+) (\d+)/
		destination = $1
		hopnumber = $2.to_i
	end
	
	if destination =~ /[\d]+\.[\d]+\.[\d]+\.[\d]+/
		nexthop = findNextHopIP(destination)
	else
		nexthop = findNextHop(destination)
	end
	if (nexthop == nil)
		realmsg = packetize("#{hopnumber+1} #{$hostname} END\\n")
		realmsg.each { |x|
			inc_socket.write(x)
		}
		inc_socket.close
	else
		realmsg = packetize("#{hopnumber+1} #{$hostname}\\n")
		realmsg.each { |x|
			inc_socket.write(x)
		}
		sock = Socket.new(AF_INET, SOCK_STREAM, 0)
		sockaddr = Socket.pack_sockaddr_in(6666, "#{nexthop}")
		sock.connect(sockaddr)
		hopmesg = packetize("TRACEROUTE #{destination} #{hopnumber+1}\\n")
		hopmesg.each { |x|
			sock.write(x)
		}
		while true
			data = sock.gets("\\n")
			if data =~ /END/
				realmsg = packetize(data)
				realmsg.each { |x|
					inc_socket.write(x)
				}
				sock.close
				inc_socket.close
				break
			else
				realmsg = packetize(data)
				realmsg.each { |x|
					inc_socket.write(x)
				}
			end
		end
	end
				
	
end	
def procSENDMSG(pack_string, inc_socket)
#	puts(pack_string)	
	fam, port, *addr = inc_socket.getpeername.unpack('nnC4')
	client = addr.join('.')
	if pack_string =~ /SENDMSG (\S+) (.*)\\n/
		destination = $1
		data = $2
	end
#	puts("about to calculate nexthop")
	if destination =~ /[\d]+\.[\d]+\.[\d]+\.[\d]+/
		nexthop = findNextHopIP(destination)
	else
		nexthop = findNextHop(destination)
	end
	if (nexthop == nil)
#		puts("At my destination")
		realmsg = packetize("Acknowledged\\n")
		realmsg.each { |x|
			inc_socket.write(x)
		}
		inc_socket.close
		puts("RECEIVED MSG FROM #{client} #{data}")
		return
	else
	sock = Socket.new(AF_INET, SOCK_STREAM, 0)
	sockaddr = Socket.pack_sockaddr_in(6666, "#{nexthop}")
	sock.connect(sockaddr)
	realmsg = packetize(pack_string)
	realmsg.each { |x|
		sock.write(x)
	}
#	puts("waiting to read")
	data = sock.gets("\\n")
	replymsg = packetize(data)
	replymsg.each{ |y|
		inc_socket.write(y)
	}
	sock.close
	end
end
def procENC(pack_string, socket)
	fam, port, *addr = inc_socket.getpeername.unpack('nnC4')
	client = addr.join('.')
	if pack_string =~ /ENC (\S+)\\n/
		destination = $1
	end
#	puts("about to calculate nexthop")
	if destination =~ /[\d]+\.[\d]+\.[\d]+\.[\d]+/
		nexthop = findNextHopIP(destination)
	else
		nexthop = findNextHop(destination)
	end
	if (nexthop == nil)
#		puts("At my destination")
	#	rsa_pair = OpenSSL::Pkey::RSA.new(2048)
		realmsg = packetize("Acknowledged\\n")
		realmsg.each { |x|
			inc_socket.write(x)
		}
		inc_socket.close
		puts("RECEIVED MSG FROM #{client} #{data}")
		return
	else
	sock = Socket.new(AF_INET, SOCK_STREAM, 0)
	sockaddr = Socket.pack_sockaddr_in(6666, "#{nexthop}")
	sock.connect(sockaddr)
	realmsg = packetize(pack_string)
	realmsg.each { |x|
		sock.write(x)
	}
#	puts("waiting to read")
	data = sock.gets("\\n")
	replymsg = packetize(data)
	replymsg.each{ |y|
		inc_socket.write(y)
	}
	sock.close
	end
	
end
def procPacket(pack_string, source, socket)
	case pack_string
		when /LSP (.*)/
			procLSP(pack_string, source)
		when /SENDMSG (.*)/
			procSENDMSG(pack_string, socket)
		when /PING (.*)/
			procPING(pack_string, socket)
		when /TRACEROUTE (.*)/
			procTRACEROUTE(pack_string, socket)
		when /ENC (.*)/
			procENC(pack_string, socket)
		else
			puts("Received an invalid message")
		end
end
def findNextHop(hostname)
$mutex.synchronize do
	ret_path = []
	source = $interfaces[0].chomp.chomp.to_sym 
	$graph.reset
	$graph.dijkstra(source)
#	$associations.each { |key, value|
	small = INFINITY
#	puts("about to find smallest cost HOSTNAME: #{hostname}")
#for some reason $associations[hostname] hangs randomly
#	puts("#{$associations[hostname.chomp].inspect}")
	$associations[hostname.chomp].each { |ip|
#			puts("lol")
#			puts("comparing costs #{ip}") 
			path, dist = $graph.shortest_path(source, ip.chomp.to_sym)
			if dist == nil
#				puts("distance was nil #{dist}")
#				puts("path was #{path.join('->')}")
				next
			end
			if dist < small
#				puts("cost was smaller #{dist}")
				small = dist
				ret_path = path
			else 
#				puts("cost was not smaller #{dist}")
			end
	}
#	puts("found smallest cost")
	#puts("HOLD back to me, can't afford the medicine")
	symInterfaces = $interfaces.map { |x| x.chomp.to_sym}
	final_path = ret_path - symInterfaces
	#if not $interfaces.include?(address.to_s)
#		while $interfaces.include?(ret_path[0].to_s)
#				ret_path.shift
#		end
#	elsif path.length != 1
#		path.shift
#	end
	if (final_path.empty?)
#		puts("at destination")
		return nil
	end
#	puts("returning next hop")
	return final_path[0].to_s
end
end
def findNextHopIP(ip)
	hostname = deassociate(ip)
	findNextHop(hostname)	
end
def dump(filename)
$mutex.synchronize do
	file = File.open(filename, 'a+')
	source = $interfaces[0].chomp.chomp.to_sym
	#print(source + "Is there a newline")
#	start = :"#{source}"
	$graph.reset
	#$graph.dijkstra(:"#{source}".to_sym)
	$graph.dijkstra(source)
	$graph.vertices.each { |key, value|
		#path, dist = $graph.shortest_path(:"#{source}".to_sym, key.to_sym)
	#puts($graph)	
	path, dist = $graph.shortest_path(source, key)
	symInterfaces = $interfaces.map { |x| x.chomp.to_sym}
	ret_path = path - symInterfaces
=begin
		if not $interfaces.include?(key.to_s)
			while $interfaces.include?(path[0].to_s)
				path.shift
			end
		elsif path.length != 1
			path.shift
		end
=end		
		#print("KEY!!!!: #{key}")	
#	if path.length != 1
#			path.shift
#		end
		destHost = deassociate(key.to_s)
#		file.puts("#{$hostname},#{key}(#{destHost}),#{dist},#{path.join('->')},#{$graph.vertices[key].dist[1]}")
		file.puts("#{$hostname},#{key}(#{destHost}),#{dist},#{ret_path[0]},#{$graph.vertices[key].dist[1]}")
	}
	file.puts($graph)
	file.puts("++++++++++++++++++++++++++++++++++++++++++++++++")
	file.close
end
end
def deassociate(ip)
	$associations.each { |key, value|
		terp = key
		if value.include?(ip)
			return terp
		end
	}
end
	
 
threadA = Thread.new do
	loop{
	sleep($routeinterval)
	$mutex.synchronize do
		$graph.dijkstra(:"#{$interfaces[0].chomp}")
	end
	}
end
threadB = Thread.new do
	loop { 
		sleep($dumpinterval)
		dump($routefile)
	#	$mutex.synchronize do
	#		puts($graph)
	#	end
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
		#client.close
#		if procPacket(data, remote_ip)
#			puts("RECEIVED MSG from #{remote_ip} #{data}")
#		end
		procPacket(data, remote_ip, client)
		client.close
	end
}

