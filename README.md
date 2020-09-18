# openpose-docker
A docker build file for CMU openpose with Python API support

![Docker Automated build](https://img.shields.io/docker/automated/revolutionarystrider/openpose-docker)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/prakashsellathurai/openpose-docker/Docker)

https://hub.docker.com/repository/docker/revolutionarystrider/openpose-docker

### Requirements
- Nvidia Docker runtime: https://github.com/NVIDIA/nvidia-docker#quickstart
- CUDA 10.0 or higher on your host, check with `nvidia-smi`

### Example
`docker run -it --rm --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0 cwaffles/openpose-python`

The Openpose repo is in `/openpose`
