require 'socket'
require 'ipaddr'
require 'optparse'
require 'timeout'
include Socket::Constants

options = {:maxlength => nil, :delay => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: node.rb -m [maxlength]"
	opts.on('-m', '--maxlength length', 'Maxmimum PacketLength') do |length|
		options[:maxlength] = length.to_i
	end
	opts.on('-d', '--delay delay', 'Initial routing delay') do |delay|
		options[:delay] = delay.to_i
	end
	
end
parser.parse!

if options[:maxlength] == nil
	puts("Maxmimum Length unspecified, defaulting to 20 bytes")
	options[:maxlength] = 20
end

$maxlen = options[:maxlength]
$delay = options[:delay]

def packetize(str)
	return str.chars.each_slice($maxlen)
end

loading = 'Loading ['
$delay.times do |d|
	j = d+1

	sleep(1)
	loading << "="
	print "\r"
	print loading + "] #{(j.to_f/$delay) * 100} %"
	$stdout.flush
end

puts("\nDone!")

while true
print("Enter a command (Type help for help):")

input = gets

	case input
		when /^SENDMSG (\S+) (.*)/
			timeout = 10
			dest = $1
			data = $2
			mesg = "SENDMSG #{dest} #{data}\\n"
			realmsg = packetize(mesg)

			sock = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.pack_sockaddr_in(6666, 'localhost')
	
			sock.connect(sockaddr)
			
			realmsg.each { |x|
				sock.write(x)
			}
			reply = ""
			begin
				Timeout::timeout 10 do
					reply = sock.gets("\\n")
				end
			rescue Timeout::Error
					reply = ""
			end
			unless reply =~ /Acknowledged/
				puts reply
				puts mesg + " failed"
			else
				puts mesg + " succesful!"
			end
			sock.close	


		when /^help/i
			puts("Client commands are of the following form\nSENDMSG [DST] [MSG]\nPING [DST] [NumPings] [DELAY]\nTRACEROUTE [DST]")
		when /^PING (\S+) (\d+) (\d+)/
			dest = $1
			numpings = $2
			delay = $3
			mesg = "PING #{dest} #{num} #{delay}\\n"
			realmsg = packetize(mesg)
			
			sock = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.pack_sockaddr_in(6666, 'localhost')
			realmsg.each { |x| 
				sock.write(x)
			}

			
		
		when /^TRACEROUTE (\S+)/
		else 
			puts("Invalid command, type help for list of valid commands")
		end
end


