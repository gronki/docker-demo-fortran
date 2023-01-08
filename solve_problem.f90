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
