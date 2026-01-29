# librespot-docker (ARM64 / Raspberry Pi)

A lightweight, optimized Docker container for [Librespot](https://github.com/librespot-org/librespot), an open source Spotify client.

This image is specifically built for **ARM64** devices (Raspberry Pi 3/4/5) and is designed to run efficiently on Kubernetes (K3s) or Docker Compose using the ALSA backend.

## Features

* **Optimized for ARM64:** Native builds using GitHub Actions runners.
* **ALSA Support:** Configured for direct hardware access or shared loops via `dmix`.
* **SD-Card Friendly:** Can be configured to write temporary cache to RAM instead of disk.
* **Configurable:** All Librespot options tunable via Environment Variables.

## 🚀 Quick Start

* `docker-compose.yaml` - Use this configuration for a standalone Raspberry Pi setup. It mounts the host's ALSA config to allow shared audio access and uses `network_mode: host` for Spotify Connect discovery.
* `k8s-deployment.yaml` - For running in a Kubernetes cluster. Note the usage of `hostNetwork`, `hostIPC`, and `supplementalGroups` to gain access to the host audio system.

## ⚙️ Configuration


| Variable | Default | Description |
| --- | --- | --- |
| `LIBRESPOT_NAME` | `Librespot Docker` | The name visible in Spotify Connect. |
| `LIBRESPOT_BACKEND` | `alsa` | Audio backend (alsa, pulseaudio, pipe, jack). |
| `LIBRESPOT_DEVICE` | `default` | ALSA device name (e.g., `hw:0,0`, `plughw:1,0`). |
| `LIBRESPOT_BITRATE` | `320` | Audio bitrate (96, 160, 320). |
| `LIBRESPOT_FORMAT` | `S32` | Output format (F32, S32, S16, etc). |
| `LIBRESPOT_INITIAL_VOLUME` | `100` | Start volume in % (0-100). |
| `LIBRESPOT_ZEROCONF_PORT` | `30242` | Create and announce a fixed port with mDNS/Discovery |

## ✅ Verification

Once the container is running, you can verify if the API is reachable and Librespot is responsive.

Replace `<IP>` with the IP address of your Raspberry Pi:

```bash
curl -v http://<IP>:30242/?action=getInfo
```

## ⚠️ Important Notes

1. **Host IPC:** If your host uses a custom `/etc/asound.conf` with `dmix` (software mixing), you **must** set `hostIPC: true` (K8s) or `ipc: host` (Docker). Without this, the container cannot access the shared memory segments required for mixing, resulting in "Device busy" errors.
2. **Tmpfs:** Librespot writes the currently playing track to disk. On Raspberry Pis, it is highly recommended to mount `/tmp` as a `tmpfs` (RAM disk) to prevent SD card wear and audio buffer underruns.
