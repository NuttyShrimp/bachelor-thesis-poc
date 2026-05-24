# Benchmark

## Load tests

On linux it's recommended to enable `tcp_tw_reuse` with the following command: `sysctl net.ipv4.tcp_tw_reuse=1`
It allows the system to directly reuse unused ports that were previously used for a TCP connection

Create a file in /etc/sysctl.d/choose-your-name.conf and put the following contents in it:

```
# Increase the maximum number of connections
net.core.somaxconn = 65535

# Increase the backlog for incoming connections
net.core.netdev_max_backlog = 65535

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Increase the range of local ports
net.ipv4.ip_local_port_range = 1024 65535

# Reuse TIME_WAIT sockets for new connections
net.ipv4.tcp_tw_reuse = 1

# Some k6 thingy
net.ipv4.tcp_timestamps=1

# Increase TCP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 87380 16777216
```

Now run `sudo sysctl -p /etc/sysctl.d/choose-your-name.conf`

After that run: `ulimit -n 250000`. This command should be ran each time you start a new terminal session where you will run `k6` in.
