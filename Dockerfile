# from https://github.com/alexgkendall/SegNet-Tutorial.git
# from https://github.com/BVLC/caffe/blob/master/docker/standalone/cpu/Dockerfile
FROM ubuntu:14.04
MAINTAINER aospan@jokersys.com

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-scipy \
        curl \
        python-tk \
        ca-certificates \
        libgtk2.0-dev && \
    curl -k https://bootstrap.pypa.io/get-pip.py  > get-pip.py && python get-pip.py && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
#slow download. put it first - this will speedup rebuilds
RUN wget "http://mi.eng.cam.ac.uk/~agk34/resources/SegNet/segnet_sun_low_resolution.caffemodel"
 
WORKDIR /opt
RUN cd /opt && git clone -b 2.4 https://github.com/Itseez/opencv.git && \
	mkdir opencv/build && cd opencv/build && \
	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ../ && \
	make -j"$(nproc)" && make -j"$(nproc)" install && rm -rf /opt/opencv

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG="segnet-cleaned"

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/alexgkendall/caffe-segnet.git . && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    mkdir build && cd build && \
    cmake -DCPU_ONLY=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

COPY segnet_demo.py /workspace
COPY segnet.sh /workspace
COPY in /workspace/in/
COPY segnet_sun_low_resolution.prototxt /workspace
COPY camvid12.png /workspace/
CMD /workspace/segnet.sh

WORKDIR /workspace
