require 'socket'
require 'ipaddr'
require 'optparse'
require 'timeout'
require 'openssl'
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
$delay = 10
def encrypt_RSA(key,message)
	key.public_encrypt(message,OPENSSL::PKey::RSA::PKCS1_OAEP_PADDING)
end

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
			puts("Client commands are of the following form\nSENDMSG [DST] [MSG]\nPING [DST] [NumPings] [DELAY]\nTRACEROUTE [DST]\nENC [DST] [MSG]")
		when /^PING (\S+) (\d+) (\d+)/
			dest = $1
			numpings = $2.to_i
			delay = $3.to_i
			mesg = "PING #{dest} #{numpings} #{delay}\\n"
			realmsg = packetize(mesg)
			
			sock = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.pack_sockaddr_in(6666, 'localhost')
			sock.connect(sockaddr)
			realmsg.each { |x| 
				sock.write(x)
			}
			numpings.times do
				sock.write("ping\\n")
				begin
					Timeout::timeout delay do
						reply = sock.gets("\\n")
						puts("RESPONSE-PING from #{dest}")
					end
				rescue Timeout::Error
					puts("PING ERROR: HOST UNREACHABLE")
				end
				sleep(delay)
			end
				sock.write("END\\n")
				sock.close
		when /^TRACEROUTE (\S+)/
			dest = $1
			realmsg = packetize("TRACEROUTE #{dest} 0\\n")
			sock = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.pack_sockaddr_in(6666, 'localhost')
			sock.connect(sockaddr)
			realmsg.each { |x|
				sock.write(x)
			}
			while true
				begin
					Timeout::timeout 10 do
						data = sock.gets("\\n")
						output = data.gsub("END", "").gsub("\\n", "")
						#output = output.slice("\\n")
						puts(output)
					end
				rescue Timeout::Error
					puts("Hop calculation took more than 10 seconds, aborting.")
				end
				if data =~ /END/
					break
				end
			end
					
		when /^ENC (\S+) (.*)/
			dest = $1
			mesg = $2
			realmsg = packetize("ENC #{dest}\\n")
			sock = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.pack_sockaddr_in(6666, 'localhost')
			sock.connect(sockaddr)
			realmsg.each { |x|
				sock.write(x)
			}
			pemfile = ""
			begin
				Timeout::timeout 10 do
					pemfile = sock.gets("\\n")
				end
			rescue Timeout::Error
					puts("Destination took too long to reply")
			end
				
			pemfile = pemfile.gsub("\\n","")
			#puts(pemfile)
			public_key = OpenSSL::PKey::RSA.new(pemfile)
			enc_msg = public_key.public_encrypt(mesg)
			realmsg = packetize("#{enc_msg}\\n")
			realmsg.each { |x|
				sock.write(x)
			}
			reply = ""
			begin 
				Timeout::timeout 10 do
					reply = sock.gets("\\n")
				end
			rescue Timeout::Error
				puts("Destination sent public key, but did not send acknowledgement in time")
			end
			if reply =~ /Acknowledged/
				puts("Encrypted message #{enc_msg} delivered succesfully")
			else
				puts("Encrypted message sent, however the recipient sent something other than an acknowledgement: #{reply}")
			end
		else 
			puts("Invalid command, type help for list of valid commands")
		end
end

