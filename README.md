# Containerizing your Fortran application using Docker

## Introduction

We all have been in this place before, where we created a code which runs fine on our local machine, and then face the distressing task of running it somewhere else (computing server, collaborator's machine, etc). It may turn out okay if we need to install it on another computer ourselves: we might run into some library issues (different versions) or compiler issues (particularly common in Fortran, where older compilers do not support some of the features of the language). However, it becomes a complete disaster when attempting to hand it over to someone not that proficient in Linux administration, or even worse -- running different OS, such as Windows or Mac OS. How do we deal with that? [Docker](https://docs.docker.com/get-started/overview/) comes with help.

## Example program

Our example program is simple, and solver the 2x2 linear equation system, using a procedure delived by LAPACK library (particularly, its modern implementation -- [OpenBLAS](https://www.openblas.net/)). The source is just one file:

```fortran
program solver

    implicit none

    real :: a(2, 2), b(2), x(2)
    character(len=128) :: input_file_name

    call get_file_name(input_file_name)

    call read_problem(input_file_name, a, b)

    call solve_problem(a, b, x)

    print *, x

contains

    subroutine get_file_name(input_file_name)
        character(len=*) :: input_file_name

        call get_command_argument(1, input_file_name)

        if (input_file_name == "") then
            print '(a)', "usage: solver <input file name>"
            stop 1
        end if
    end subroutine

    subroutine read_problem(input_file_name, a, b)
        real :: a(2, 2), b(2)
        character(len=128) :: input_file_name

        open(unit=11, file=input_file_name, action='read')
        read(unit=11, fmt=*) a(1,:), b(1)
        read(unit=11, fmt=*) a(2,:), b(2)
        close(unit=11)

    end subroutine

    subroutine solve_problem(a, b, x)
        interface
            SUBROUTINE sgesv( N, NRHS, A, LDA, IPIV, B, LDB, INFO )
                INTEGER            INFO, LDA, LDB, N, NRHS
                INTEGER            IPIV( * )
                REAL               A( LDA, * ), B( LDB, * )
            end SUBROUTINE
        end interface

        real :: a(2, 2), b(2), x(2)
        integer :: ipiv(2), info

        x(:) = b(:)
        call sgesv(2, 1, a, 2, ipiv, x, 2, info)

        if (info /= 0) then
            error stop 'sgesv failed to compute the result'
        end if

    end subroutine

end program
```

Typically, on a Linux machine, we would compile it using a command:

```bash
f95 -g -O2 solve_problem.f90 -lopenblas -o solve_problem
```

The example usage would be solving a following equation system:

```
1x + 2y = 5
3x + 2y = 7
```

We must put our coefficients into a file, and the pass the file name as the program argument:

```bash
cat > input.txt <<EOF
1.0 2.0   5.0
3.0 2.0   7.0
EOF
./solve_problem input.txt
```

We would get an output:

```
   1.00000000       2.00000000    
```

## Creating the image

Building an image can be translated as "building the minimal Linux environment, that has all the required components for our program to run". In our example, we are based on Ubuntu, a very popular Linux distribution. The manifest file where we describe how to build the environment is named **Dockerfile**. In the first part, we specify that our image is based on ubuntu, and install the required libraries (OpenBLAS, in our case):

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
```

Next, we copy the content of the folder (assuming it is the main repository directory) into the image filesystem under the destination ``/opt/build``, compile our program, install it and clean up after the build:

```Dockerfile
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
```

The last step is to specify the working directory after a new container is created from our image and what should be executed at the start:

```Dockerfile
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
