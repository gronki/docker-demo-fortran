# Containerizing your Fortran application using Docker

## Introduction

We all have been in this place before, where we created a code which runs fine on our local machine, and then face the distressing task of running it somewhere else (computing server, collaborator's machine, etc). It may turn out okay if we need to install it on another computer ourselves: we might run into some library issues (different versions) or compiler issues (particularly common in Fortran, where older compilers do not support some of the features of the language). However, it becomes a complete disaster when attempting to hand it over to someone not that proficient in Linux administration, or even worse -- running different OS, such as Windows or Mac OS. How do we deal with that? (Docker)[https://docs.docker.com/get-started/overview/] comes with help.

## Example program

Our example program is simple, and solver the 2x2 linear equation system, using a procedure delived by LAPACK library (particularly, its modern implementation -- (OpenBLAS)[https://www.openblas.net/]). 
