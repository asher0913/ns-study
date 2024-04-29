#!/usr/bin/awk -f
BEGIN {
    # Initialize variables
    total_delay = 0;
    total_packets = 0;
    total_dropped_packets = 0;
    start_time = 0;
    end_time = 0;
}
{
    split($0, fields, " ");
    event_type = fields[1];      # Event type (s: send, r: receive, d: drop)
    time = fields[2];            # Time of event
    from_node = fields[3];       # From node
    to_node = fields[4];         # To node
    pkt_type = fields[5];        # Packet type (tcp, cbr, etc.)
    pkt_size = fields[6];        # Packet size in bytes
    seq_num = fields[7];         # Packet sequence number
    # Calculate total throughput and delay
    if (event_type == "s" && pkt_size >= 512) {
        # Packet sent
        send_time[seq_num] = time;
    } else if (event_type == "r" && pkt_size >= 512) {
        # Packet received
        if (seq_num in send_time) {
            delay = time - send_time[seq_num];
            total_delay += delay;
            total_packets++;
        }
    } else if (event_type == "D" && pkt_size >= 512) {
        # Packet dropped
        total_dropped_packets++;
    }
    # Track start and end time for throughput calculation
    if (start_time == 0 || time < start_time) {
        start_time = time;
    }
    if (end_time == 0 || time > end_time) {
        end_time = time;
    }
}
END {
    # Calculate statistics
    sim_time = end_time - start_time;
    throughput = (total_packets * 8 / sim_time);
    avg_delay = (total_delay / total_packets)*1000; # ms
    packet_drop_rate = (total_dropped_packets / (total_packets + total_dropped_packets))*100; # Drops per packet

    # Output results
    printf("%.6f %.2f %.6f\n",  avg_delay, throughput, packet_drop_rate);
}
