#!/usr/bin/ruby

file = ARGV[0]
configFile = File.open(file, 'r')
hostname = `hostname`
hostname.chomp!
line = configFile.gets
args = line.split(",")
file.close

length = args[0]
weightfile = args[1]
routeinterval = args[2]
routefile = args[3]
dumpinterval = args[4]

if length == nil or weightfile == nil or routeinterval == nil or routefile == nil or dumpinterval == nil
	puts("invalid config file. Format should be a single, comma seperated line with the following fields\n[Maximum Packet Size],[Weights File],[Routing Interval],[Routing Table Output Directroy],[Dump Interval].\n\nRouting Table dumps will be found in the directory you specified under the file name #{hostname}.dump.")
exit
end

system("ruby /home/core/OverlayRPC2/graph.rb -w #{weightfile} -r #{routefile} -d #{dumpinterval} -rt #{routeinterval} -ml #{length} &")
system("ruby /home/core/OverlayRPC2/sendLSP.rb -d #{routeinterval.to_i / 3} -l #{length} -t 5 &")


