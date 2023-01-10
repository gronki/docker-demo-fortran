# Containerizing your Fortran application using Docker

## Introduction

We all have been in this place before, where we created a code which runs fine on our local machine, and then face the distressing task of running it somewhere else (computing server, collaborator's machine, etc). It may turn out okay if we need to install it on another computer ourselves: we might run into some library issues (different versions) or compiler issues (particularly common in Fortran, where older compilers do not support some of the features of the language). However, it becomes a complete disaster when attempting to hand it over to someone not that proficient in Linux administration, or even worse -- running different OS, such as Windows or Mac OS. How do we deal with that? [Docker](https://docs.docker.com/get-started/overview/) comes with help.

## Example program

Our example program is simple, and solver the 2x2 linear equation system, using a procedure delived by LAPACK library (particularly, its modern implementation -- [OpenBLAS](https://www.openblas.net/)). The [source](https://github.com/gronki/docker-demo-fortran/blob/master/solve_problem.f90) is just one file. Typically, on a Linux machine, we would compile it using a command:

```bash
f95 -g -O2 solve_problem.f90 -lopenblas -o solve_problem
```

That is, provided that the library we use is installed on the Linux system. 

## Creating the image

Building an image can be translated as "building the minimal Linux environment, that has all the required components for our program to run". In our example, we are based on Ubuntu, a very popular Linux distribution. The manifest file where we describe how to build the environment is named **Dockerfile**. 

```Dockerfile
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
```
