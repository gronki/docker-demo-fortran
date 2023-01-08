# base this image on the last release of Ubuntu
FROM ubuntu

# install the required environment and then clean up the cache
# to not unnecesarily bloat the image
# notice we choose to do it in one RUN block, to not create
# extra layers
RUN apt-get update && \
    apt-get install -y gfortran libopenblas-dev && \
    apt-get clean

# copy the whole directory content into /opt/build
# excluding the files specified in .dockerignore
# which typically will be similar to .gitignore
COPY . /opt/build/

# in this step, we enter the build directory and compile our program.
# we then install it to /usr/local/bin directory and delete
# the build directory, again to make the image smaller.
# the directory change does not propagate to any following
# Dockerfile statements, this is why we executed it all in one
# RUN block, joining the commands with &&
RUN cd /opt/build && \
    f95 -g -O2 solve_problem.f90 -lopenblas -o solve_problem && \
    install solve_problem /usr/local/bin/ && \
    rm -rf /opt/build

# this specified, that /work should be mounted as a volume
# since Docker containers are isolated from your local data
# unless you specifically grant them access
VOLUME [ "/work" ]

# this actually changes the working directory to /work
WORKDIR /work

# finally, we specify what command will be executed
# when the container is run. this is of course our program
ENTRYPOINT ["/usr/local/bin/solve_problem"]