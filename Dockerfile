
FROM nvidia/cuda:8.0-cudnn5-devel

LABEL maintainer "Prakash Sellathurai <prakashsellathurai@gmail.com>"



# install dependencies
RUN apt-get update && \
  apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libjpeg8-dev \
    libtiff5-dev \
    libjasper-dev \
    libpng12-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libx264-dev \
    libx265-dev \
    libatlas-base-dev \
    gfortran \
    python3.5-dev \
    libboost-all-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libprotobuf-lite9v5 \
    libprotobuf-dev \
    protobuf-compiler \
    wget \
    unzip \
    python3-pip \
    libhdf5-serial-dev \
    libleveldb-dev \
    liblmdb-dev \
    libsnappy-dev \
    yasm && \
  rm -rf /var/lib/apt/lists/*

# upgrade pip(3)
RUN pip3 install --upgrade pip && \
  pip3 install numpy scipy

# opencv (3.2 specifically)
# ensure dnn is NOT enabled, this will cause problems!
RUN cd ~ && \
    export OPENCV_CHECKSUM=7a7d2eb8cf617f58d610d856e531f3d92b89bc42 && \
    export OPENCV_CONTRIB_CHECKSUM=9f34aef18d05cf7136d6b251c794cfdfcdb2e78d && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/3.2.0.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/3.2.0.zip && \
    echo "${OPENCV_CHECKSUM}  opencv.zip" | sha1sum -c && \
    echo "${OPENCV_CONTRIB_CHECKSUM}  opencv_contrib.zip" | sha1sum -c && \
    unzip opencv.zip && \
    unzip opencv_contrib.zip && \
    rm -f opencv.zip && \
    rm -f opencv_contrib.zip

RUN cd ~/opencv-3.2.0/ && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D INSTALL_PYTHON_EXAMPLES=OFF \
      -D INSTALL_C_EXAMPLES=OFF \
      -D BUILD_opencv_dnn=OFF \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-3.2.0/modules \
      -D PYTHON3_EXECUTABLE=/usr/bin/python3 \
      -D BUILD_opencv_python2=OFF \
      -D BUILD_opencv_python3=ON \
      -D BUILD_EXAMPLES=OFF .. && \
    make -j"$(nproc)" && \
    make install -j"$(nproc)" && \
    ldconfig && \
    cd ~ && \
    rm -rf opencv-3.2.0 && \
    rm -rf opencv_contrib-3.2.0

RUN cd /opt && \
    export OPENPOSE_CHECKSUM=9f34aef18d05cf7136d6b251c794cfdfcdb2e78d && \
    wget -O openpose.zip https://github.com/CMU-Perceptual-Computing-Lab/openpose/archive/v1.2.1.zip && \
    && echo "${OPENCV_CHECKSUM}  opencv.zip" | sha1sum -c && \
    unzip openpose.zip && \
    rm -f openpose.zip && \
    mv openpose-1.2.1 openpose-master

ENV CAFFE_ROOT=/opt/openpose-master/3rdparty/caffe

# caffe
RUN cd /opt/openpose-master && \
    rm -rf 3rdparty/caffe && \
    git clone --depth 1 https://github.com/CMU-Perceptual-Computing-Lab/caffe.git 3rdparty/caffe && \
    cd 3rdparty/caffe/ && \
    cp Makefile.config.Ubuntu16_cuda8.example Makefile.config && \
    sed -i '/\# OPENCV_VERSION := 3/c\OPENCV_VERSION := 3' Makefile.config && \
    sed -i '/\# PYTHON_LIBRARIES := boost_python3 python3.5m/c\PYTHON_LIBRARIES := boost_python3 python3.5m' Makefile.config && \
    sed -i '/\# PYTHON_INCLUDE := \/usr\/include\/python3.5m \\/c\PYTHON_INCLUDE := \/usr\/include\/python3.5m \\' Makefile.config && \
    sed -i '/\#                 \/usr\/lib\/python3.5\/dist-packages\/numpy\/core\/include/c\                  \/usr\/local\/lib\/python3.5\/dist-packages\/numpy\/core\/include' Makefile.config && \
    cd python && \
    for req in $(cat requirements.txt) pydot; do pip install $req; done && \
    cd .. && \
    ln -s /usr/lib/x86_64-linux-gnu/libboost_python-py35.so /usr/lib/x86_64-linux-gnu/libboost_python3.so && \
    make all -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# and distribute
RUN cd /opt/openpose-master/3rdparty/caffe/ && \
    make distribute -j"$(nproc)"

# compile openpose
ENV OPENPOSE_ROOT /opt/openpose-master
RUN cd /opt/openpose-master && \
    cp ubuntu/Makefile.config.Ubuntu16_cuda8.example Makefile.config && \
    sed -i '/\# OPENCV_VERSION := 3/c\OPENCV_VERSION := 3' Makefile.config && \
    make all -j"$(nproc)"
