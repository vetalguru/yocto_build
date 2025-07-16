# Yocto Build System in Docker

This repository provides a fully automated Yocto (kirkstone branch) build system within a Docker container. The project simplifies the process of setting up the Yocto environment and building images without modifying your host system.


## Features

- Isolated Yocto build environment using Docker
- Automatically clones the official `poky` Yocto repository (branch: `kirkstone`)
- Easy configuration via `config.cfg`
- Modular bash scripts for Dockerfile generation, image build, container execution, and Yocto build


## Requirements

- Docker
- Git
- Bash-compatible shell (Linux/macOS/WSL)


## Quick Start

1. Edit `scripts/config.cfg` if needed.

2. Run the build process:

   ```bash
   .scripts/yocto_build.sh
   ```

This script will:
- Generate a Dockerfile
- Build the Docker image
- Clone the Yocto `poky` repository
- Start a container and run the Yocto build


## License

This project is provided as-is for educational and research purposes. Use at your own discretion.

