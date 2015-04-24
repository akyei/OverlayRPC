require 'socket'
require 'ipaddr'
include Socket::Constants
$maxlen = 20

def packetize(str)
	return str.chars.each_slice($maxlen).map(&:join)
end

while true

    input = gets
    
    case input
        when /SENDMSG (\S+) (.*)/
            # Parsing command
            dest = $1
            str = $2
            
            # Creating socket
            mesg = "SENDMSG " + dest + " " + str
            realmsg = packetize(mesg)
            sock = Socket.new(AF_INET, SOCK_STREAM, 0)
            sockaddr = Socket.pack_sockaddr_in(6666, dest.chomp)
            sock.connect(sockaddr)
            
            # Sending Packet
            realmsg.each{ |x|
                sock.write(x)
            }
	    
	    reply = sock.gets("\\n")
	    unless reply = "Acknowledged"
	    	puts mesg + " failed"
	    sock.close
 
        when /PING (\S+) (\d+) (\d+)/
            # Parsing command
            dest = $1
            numpings = $2
            delay = $3
            
            # Creating socket
            mesg = "PING " + dest + " " + num + " " + delay  
            realmsg = packetize(mesg)
            sock = Socket.new(AF_INET, SOCK_STREAM, 0)
            sockaddr = Socket.pack_sockaddr_in(6666, dest.chomp)
            sock.connect(sockaddr)

            # Sending Packet
            realmsg.each{ |x|
                sock.write(x)
            }          

	    reply = sock.gets("\\n")
	    unless reply = "Acknowledged"
	    	puts mesg + " failed"
	    sock.close

        when /TRACEROUTE (\S+)/
            # Parsing command
            dest = $1       

            # Creating socket
            mesg = "TRACEROUTE " + dest
            realmsg = packetize(mesg)
            sock = Socket.new(AF_INET, SOCK_STREAM, 0)
            sockaddr = Socket.pack_sockaddr_in(6666, dest.chomp)
            sock.connect(sockaddr)
 
            # Sending Packet         
            realmsg.each{ |x|
                sock.write(x)
            }   

	    reply = sock.gets("\\n")
	    unless reply = "Acknowledged"
	    	puts mesg + " failed"
	    sock.close
        else
            puts "Invalid query"
        end
    end 
