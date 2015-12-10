class PingHostParser:

    def get_parsed_data(self, input, delimiter=' '):
        pydict = dict()

        lines = input.split("\n")
        if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                    (lines[0].upper().find("NOT FOUND") > 0) or
                    (len(lines) == 1 and lines[0].strip() == ""))):
            return pydict

        ###
        # nsx-manager> ping time.vmware.com
        # PING scrootdc02.vmware.com (10.113.60.176): 56 data bytes
        # 64 bytes from 10.113.60.176: icmp_seq=0 ttl=116 time=217.596 ms
        # 64 bytes from 10.113.60.176: icmp_seq=1 ttl=116 time=227.690 ms
        # 64 bytes from 10.113.60.176: icmp_seq=3 ttl=116 time=212.202 ms
        # ^C--- scrootdc02.vmware.com ping statistics ---
        # 4 packets transmitted, 4 packets received, 0% packet loss
        # round-trip min/avg/max/stddev = 212.115/212.517/213.320/0.478 ms
        ###

        for line in lines:
            if line.find("time=") > 0:
                # Calculate packet loss
                packets_info = lines[-4].strip().split(',')
                p_transmitted = int(packets_info[0].split()[0])
                p_received = int(packets_info[1].split()[0])
                pydict.update({'packet_loss': p_transmitted - p_received})

                pydict.update({'status': 'ping succeeded'})
                break
            elif line.find("Destination Host Unreachable") > 0:
                pydict.update({'status': 'Destination Host Unreachable'})
                break
            elif line.find("unknown host") > 0:
                pydict.update({'status': 'ping: unknown host'})
                break

        return pydict