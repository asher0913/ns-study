# q1.tcl - A script to simulate a circular wireless topology with TCP and UDP flows

if { [llength $argv] >= 3 } {
    set trace_filename [lindex $argv 0]
    set nam_filename [lindex $argv 1]
    set val(stop) [lindex $argv 2]
} else {
    set trace_filename "q1.tr"
    set nam_filename "q1.nam"
    set val(stop) 1000 ;# simulation time
}

set trace_file [open $trace_filename w]
set nam_file [open $nam_filename w]
# Set up simulation parameters
set ns [new Simulator]


# Define options
set val(chan) Channel/WirelessChannel;
set val(prop) Propagation/TwoRayGround;
set val(netif) Phy/WirelessPhy;
set val(mac) Mac/802_11;
set val(ifq) Queue/DropTail/PriQueue;
set val(ll) LL;
set val(ant) Antenna/OmniAntenna;
set val(ifqlen) 50;
set val(rp) AODV;
set val(nn) 10;
set val(x) 500;
set val(y) 500;

# Setup the topography object
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Trace and NAM setup
$ns trace-all $trace_file
$ns namtrace-all-wireless $nam_file $val(x) $val(y)

create-god $val(nn)

set chan_1_ [new $val(chan)]

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channel $chan_1_ \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace ON \
       
# Create nodes and place them in a circle
for {set i 0} {$i < $val(nn)} {incr i} {
    set node_($i) [$ns node]
    set angle [expr {2.0 * 3.1415926535 * $i / $val(nn)}]
    set xpos [expr {$val(x) / 2 + cos($angle) * 400}]
    set ypos [expr {$val(y) / 2 + sin($angle) * 400}]
    $node_($i) set X_ $xpos
    $node_($i) set Y_ $ypos
    $ns initial_node_pos $node_($i) 20
}

# Randomly choose senders and receivers once
set rng [new RNG]
$rng seed 0
set senders {}
set receivers {}

for {set i 0} {$i < $val(nn)} {incr i} {
    if {[expr {int(rand() * 10)}] < 2} {
        lappend senders $i
    } elseif {[expr {int(rand() * 10)}] < 4} {
        lappend receivers $i
    }
}

# Ensure that senders and receivers are not the same nodes
foreach sender $senders {
    if {$sender in $receivers} {
        set receivers [lreplace $receivers [lsearch -exact $receivers $sender] [lsearch -exact $receivers $sender]]
    }
}

# Establish TCP and UDP connections between nodes
foreach idx [array names node_] {
    set sender $node_($idx)
    set receiver $node_([expr {($idx + 1) % $val(nn)}])
    if {($idx % $val(nn)) < ($val(nn) * 0.2)} {
        # Setup TCP connection
        set tcp [new Agent/TCP]
        set sink [new Agent/TCPSink]
        $ns attach-agent $sender $tcp
        $ns attach-agent $receiver $sink
        $ns connect $tcp $sink
        set ftp [new Application/FTP]
        $ftp attach-agent $tcp
        $ns at 0.1 "$ftp start"
    } 
    if {($val(nn) * 0.2) < ($idx % $val(nn)) < ($val(nn) * 0.4)} {
        # Setup UDP connection
        set udp [new Agent/UDP]
        set null [new Agent/Null]
        $ns attach-agent $sender $udp
        $ns attach-agent $receiver $null
        $ns connect $udp $null
        set cbr [new Application/Traffic/CBR]
        $cbr set packetSize_ 512
        $cbr set interval_ 0.05
        $cbr attach-agent $udp
        $ns at 0.1 "$cbr start"
    }
}

for {set i 0} {$i < $val(nn)} {incr i} {
        $ns initial_node_pos $node_($i) 30
}

for {set i 0} {$i < $val(nn)} {incr i} {
	$ns at $val(stop) "$node_($i) reset";
}

# Define the stop function
proc stop {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
    exit 0
}

# Schedule the end of the simulation
$ns at $val(stop) "stop"

# Run the simulation
$ns run

# Close the simulation
stop
