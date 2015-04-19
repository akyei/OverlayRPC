require 'socket'
require 'ipaddr'
include Socket::Constants

$sequence = 0
lead = `hostname`
lead = lead.chomp!
shittytext = `ifconfig | grep 'inet addr' | awk -F : '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1`
neighbors = {}

ipArr = shittytext.split('\n')


def packetize(str, maxlen)
	arr = []
	n = ((str.length.to_f / maxlen)).ceil
	0.step(n-1, 1) { |i|
		arr[i] = str[i*maxlen,i+1*maxlen]
	}
	return arr
end 


while true
	if $sequence == 0 
		sleep(ARGV[1].to_i / 3)
	else
		sleep(ARGV[1].to_i)
	end
	configFile = File.open(ARGV[0], 'r')
	while (line = configFile.gets())
		arr = line.split(",")
		if (ipArr[0].include?("#{arr[0]}")) then
	 		neighbors["#{arr[1]}"] = arr[2].to_i
		else
		end
	end
	
	configFile.close
	$sequence += 1
	str = ""
	ipArr[0].each { |key|
		str << "#{key.chomp!}:0 "
	}
	neighbors.each { |key, value| 
		str << "#{key}:#{value} "
	}
	
	str = str.chop
	ipArr[0].each { |key|
		key = key.chomp!
		lsp_string2 = "LSP #{key} #{lead} #{$sequence} \"#{str}\"\\n"
		realMsg = packetize(lsp_string2, 50)
		neighbors.each { |key, value|
			socket = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.sockaddr_in(6666, "#{key}")
			socket.connect(sockaddr)
			realMsg.each {|x|
				socket.write(x)
			}
			
			socket.close
		}
	}	
end


