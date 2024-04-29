#!/usr/bin/awk -f
BEGIN {
    # Initialize variables for both TCP and UDP (CBR)
    tcp_total_delay = 0; tcp_total_packets = 0; tcp_total_dropped_packets = 0;
    udp_total_delay = 0; udp_total_packets = 0; udp_total_dropped_packets = 0;
    start_time = 0; end_time = 0;
}

{
    split($0, fields, " ");
    event_type = fields[1];      # Event type (s: send, r: receive, d: drop)
    time = fields[2];            # Time of event
    pkt_type = fields[7];        # Packet type (tcp, cbr)
    pkt_size = fields[9];        # Packet size in bytes
    seq_num = fields[4];         # Sequence number

    # Track start and end time for throughput calculation
    if (start_time == 0 || time < start_time) {
        start_time = time;
    }
    if (end_time == 0 || time > end_time) {
        end_time = time;
    }

    if (pkt_size >= 512) {  # We filter out packets smaller than 512 bytes
        if (event_type == "s") {
            send_time[pkt_type, seq_num] = time;  # Record send time for each packet type and seq_num
        } else if (event_type == "r" && (pkt_type, seq_num) in send_time) {
            delay = time - send_time[pkt_type, seq_num];
            if (pkt_type == "tcp") {
                tcp_total_delay += delay;
                tcp_total_packets++;
            } else if (pkt_type == "cbr") {
                udp_total_delay += delay;
                udp_total_packets++;
            }
        } else if (event_type == "D") {
            if (pkt_type == "tcp") {
                tcp_total_dropped_packets++;
            } else if (pkt_type == "cbr") {
                udp_total_dropped_packets++;
            }
        }
    }
}

END {
    # Calculate statistics for TCP
    tcp_throughput = (tcp_total_packets * 8 / (end_time - start_time));
    tcp_avg_delay = (tcp_total_delay / tcp_total_packets)*1000;  # ms
    tcp_packet_drop_rate = (tcp_total_dropped_packets / (tcp_total_packets + tcp_total_dropped_packets)) * 100;  # Drop rate percentage

    # Calculate statistics for UDP (CBR)
    udp_throughput = (udp_total_packets * 8 / (end_time - start_time));
    udp_avg_delay = (udp_total_delay / udp_total_packets)*1000;  # ms
    udp_packet_drop_rate = (udp_total_dropped_packets / (udp_total_packets + udp_total_dropped_packets)) * 100;  # Drop rate percentage

    # Output results for TCP and UDP
    printf("TCP,%.6f,%.8f,%.2f\n", tcp_avg_delay, tcp_throughput, tcp_packet_drop_rate);
    printf("UDP,%.6f,%.8f,%.2f\n", udp_avg_delay, udp_throughput, udp_packet_drop_rate);
}
