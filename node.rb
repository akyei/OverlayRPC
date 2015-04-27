#!/usr/bin/ruby

file = ARGV[0]
configFile = File.open(file, 'r')
hostname = `hostname`
hostname.chomp!
line = configFile.gets
args = line.split(",")
configFile.close

length = args[0].to_i
weightfile = args[1]
routeinterval = args[2].chomp.to_i
routefile = args[3]
dumpinterval = args[4]
puts(routeinterval)

if length == nil or weightfile == nil or routeinterval == nil or routefile == nil or dumpinterval == nil
	puts("invalid config file. Format should be a single, comma seperated line with the following fields\n[Maximum Packet Size],[Weights File],[Routing Interval],[Routing Table Output Directroy],[Dump Interval].\n\nRouting Table dumps will be found in the directory you specified under the file name #{hostname}.dump.")
exit
end
#puts("ruby /home/core/OverlayRPC2/graph.rb -w #{weightfile} -r #{routefile} -d #{dumpinterval} -q #{routeinterval} -m #{length}")
fork do
exec("ruby /home/core/OverlayRPC2/graph.rb -w #{weightfile} -r #{routefile} -d #{dumpinterval} -q #{routeinterval} -m #{length} ")
end
fork do
exec("ruby /home/core/OverlayRPC2/sendLSP.rb -d #{routeinterval.to_i} -l #{length} -t 3 -f #{weightfile} ")
end 
exec("ruby /home/core/OverlayRPC2/client.rb -d #{routeinterval.to_i} -m #{length}")

