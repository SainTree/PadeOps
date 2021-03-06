module cgrid_hooks
    use kind_parameters, only: rkind
    use decomp_2d,       only: decomp_info
    use DerivativesMod,  only: derivatives
    use MixtureEOSMod,   only: mixture
    implicit none

    interface meshgen
        subroutine meshgen(decomp, dx, dy, dz, mesh)
            import :: rkind
            import :: decomp_info
            type(decomp_info),               intent(in)    :: decomp
            real(rkind),                     intent(inout) :: dx, dy, dz
            real(rkind), dimension(:,:,:,:), intent(inout) :: mesh

        end subroutine 
    end interface

    interface initfields
        subroutine initfields(decomp,dx,dy,dz,inputfile,mesh,fields,mix,tstop,dt,tviz)
            import :: rkind
            import :: decomp_info
            import :: mixture
            type(decomp_info),               intent(in)    :: decomp
            type(mixture),                   intent(inout) :: mix
            real(rkind),                     intent(in)    :: dx, dy, dz
            character(len=*),                intent(in)    :: inputfile
            real(rkind), dimension(:,:,:,:), intent(in)    :: mesh
            real(rkind), dimension(:,:,:,:), intent(inout) :: fields
            real(rkind),                     intent(inout) :: tstop, dt, tviz

        end subroutine 
    end interface


    interface hook_output
        subroutine hook_output(decomp,der,dx,dy,dz,outputdir,mesh,fields,mix,tsim,vizcount)
            import :: rkind
            import :: decomp_info
            import :: derivatives
            import :: mixture
            character(len=*),                intent(in) :: outputdir
            type(decomp_info),               intent(in) :: decomp
            type(mixture),                   intent(in) :: mix
            type(derivatives),               intent(in) :: der
            real(rkind),                     intent(in) :: dx,dy,dz,tsim
            integer,                         intent(in) :: vizcount
            real(rkind), dimension(:,:,:,:), intent(in) :: mesh
            real(rkind), dimension(:,:,:,:), intent(in) :: fields

        end subroutine
    end interface

    interface hook_bc
        subroutine hook_bc(decomp,mesh,fields,mix,tsim)
            import :: rkind
            import :: decomp_info
            import :: mixture
            type(decomp_info),               intent(in)    :: decomp
            type(mixture),                   intent(in)    :: mix
            real(rkind),                     intent(in)    :: tsim
            real(rkind), dimension(:,:,:,:), intent(in)    :: mesh
            real(rkind), dimension(:,:,:,:), intent(inout) :: fields

        end subroutine
    end interface

    interface hook_timestep
        subroutine hook_timestep(decomp,mesh,fields,mix,step,tsim)
            import :: rkind
            import :: decomp_info
            import :: mixture
            type(decomp_info),               intent(in) :: decomp
            type(mixture),                   intent(in) :: mix
            integer,                         intent(in) :: step
            real(rkind),                     intent(in) :: tsim
            real(rkind), dimension(:,:,:,:), intent(in) :: mesh
            real(rkind), dimension(:,:,:,:), intent(in) :: fields

        end subroutine
    end interface

    interface hook_source
        subroutine hook_source(decomp,mesh,fields,mix,tsim,rhs,rhsg)
            import :: rkind
            import :: decomp_info
            import :: mixture
            type(decomp_info),               intent(in)    :: decomp
            type(mixture),                   intent(in)    :: mix
            real(rkind),                     intent(in)    :: tsim
            real(rkind), dimension(:,:,:,:), intent(in)    :: mesh
            real(rkind), dimension(:,:,:,:), intent(in)    :: fields
            real(rkind), dimension(:,:,:,:), intent(inout) :: rhs
            real(rkind), dimension(:,:,:,:), optional, intent(inout) ::rhsg

        end subroutine
    end interface

end module 
