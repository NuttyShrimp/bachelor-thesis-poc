# Benchmark

## Load tests

On linux it's recommended to enable `tcp_tw_reuse` with the following command: `sysctl net.ipv4.tcp_tw_reuse=1`
It allows the system to directly reuse unused ports that were previously used for a TCP connection

```
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
sudo sysctl -w net.ipv4.tcp_tw_reuse=1
sudo sysctl -w net.ipv4.tcp_timestamps=1
ulimit -n 250000
```
