---
description: Diagnose why a VM (Gnome Boxes/libvirt/QEMU) is slow or unresponsive
---

Diagnose VM performance issues by checking both host and guest resource contention.

## Step 0: Start by announcing you're using this skill
It's important to confirm with the user that you're using the skill properly.

## Step 1: Identify running VMs
```bash
virsh list --all
```

## Step 2: Run these diagnostic commands in parallel

**Host overview:**
```bash
top -bn1 | head -20
```

**Find QEMU processes:**
```bash
pgrep -a qemu
```

**Memory:**
```bash
free -h
```

**VM-specific stats (replace VM_NAME):**
```bash
virsh domstats VM_NAME
```

**QEMU process details (replace PID):**
```bash
cat /proc/PID/status | grep -E "^(Name|State|Threads|VmRSS|voluntary|nonvoluntary)"
```

## Step 3: Analyze results

Key things to look for:

1. **Host CPU saturation**: Load average > number of cores means CPU starvation
2. **Competing processes**: Compilers (cc1plus, clang), browsers, Java apps consuming CPU
3. **vCPU delays**: In `virsh domstats`, check `vcpu.X.delay` - high values (billions of ns) mean the VM is waiting for host CPU
4. **vCPU blocking state**: `vcpu.X.blocking.cur=yes` means vCPU is halted waiting for work OR waiting for CPU time
5. **Memory pressure**: Check if host is swapping (`free -h` swap used)
6. **I/O bottlenecks**: High `block.X.wr.times` relative to `block.X.wr.reqs` indicates slow disk

## Common patterns

| Symptom | Host shows | Guest htop shows | Cause |
|---------|-----------|------------------|-------|
| VM slow, host busy | High load, other processes at 100% | Low CPU usage | Host CPU starvation - VM can't get time slices |
| VM slow, host idle | Low load | High iowait | Disk I/O bottleneck (check qcow2 fragmentation) |
| VM slow, both busy | High load | High CPU usage | Legitimate high workload, may need more resources |

## Common patterns (continued)

| Symptom | Cause | Solution |
|---------|-------|----------|
| Slow UI redraw (visible top-to-bottom refresh) | Heavy swap usage, even with free RAM | Clear swap with `sudo swapoff -a` (safe if available RAM > swap used) |

## Quick fixes

- **CPU starvation**: `renice 19 -p $(pgrep -d, PROCESS_NAME)` to deprioritize competing processes
- **Too many vCPUs**: Reduce VM vCPUs to 2-4 when host is busy
- **I/O issues**: Consider switching qcow2 to raw format or enabling `cache=none`
- **Swap thrashing**: If swap is heavily used but RAM is available, clear it with `sudo swapoff -a`. To restore: check `swapon --show` first - if it's zram, use `sudo systemctl restart systemd-zram-setup@zram0` (not `swapon -a`, which only reads fstab)
- **Memory overcommit**: Total VM RAM + host needs should not exceed physical RAM. Each VM with 4GB + host apps can easily exhaust 32GB

## Additional diagnostic commands

**Real-time VM stats:**
```bash
virt-top
```

**QEMU monitor access:**
```bash
virsh qemu-monitor-command VM_NAME --hmp "info cpus"
virsh qemu-monitor-command VM_NAME --hmp "info status"
```

**Disk I/O for VM:**
```bash
virsh domblkstat VM_NAME vda
```
