subroutine DoGlobalDynamicProcedure(this, uhatE, vhatE, whatE, uE, vE, wE, duidxjEhat, duidxjE)
   class(sgs_igrid), intent(inout) :: this
   real(rkind), dimension(this%gpE%xsz(1),this%gpE%xsz(2),this%gpE%xsz(3)), intent(in) :: uE, vE, wE
   complex(rkind), dimension(this%sp_gpE%ysz(1),this%sp_gpE%ysz(2),this%sp_gpE%ysz(3))  , intent(in) :: uhatE, vhatE, whatE
   complex(rkind), dimension(this%sp_gpE%ysz(1),this%sp_gpE%ysz(2),this%sp_gpE%ysz(3),9), intent(in) :: duidxjEhat
   real(rkind), dimension(this%gpE%xsz(1),this%gpE%xsz(2),this%gpE%xsz(3),9), intent(in) :: duidxjE
   integer :: idx 
   real(rkind) :: num, den

   do idx = 1,9
      call this%TestFilter_Cmplx_to_Real( duidxjEhat(:,:,:,idx), this%alphaij_filt(:,:,:,idx))
   end do
   call get_Sij_from_duidxj(this%alphaij_filt, this%Sij_filt, size(this%Sij_filt,1),size(this%Sij_filt,2),size(this%Sij_filt,3))

   call this%TestFilter_Cmplx_to_Real(uhatE, this%ui_Filt(:,:,:,1))   
   call this%TestFilter_Cmplx_to_Real(vhatE, this%ui_Filt(:,:,:,2))   
   call this%TestFilter_Cmplx_to_Real(whatE, this%ui_Filt(:,:,:,3))   
   
   call this%TestFilter_Cmplx_to_Real(whatE, this%ui_Filt(:,:,:,3))   

   call this%interp_bForce_CellToEdge()
   do idx = 1,3
      call this%TestFilter_Real_to_Real(this%fiE(:,:,:,idx),this%fi_filt(:,:,:,idx))
   end do 

   select case (this%mid)
   case (0) ! smagorinsky
      call get_smagorinsky_kernel(this%Sij_filt,this%Dsgs_filt, &
                              this%gpE%xsz(1),this%gpE%xsz(2),this%gpE%xsz(3))
   case (1) ! sigma
      call get_sigma_kernel(this%Dsgs_filt, this%alphaij_Filt, &
                              this%gpE%xsz(1),this%gpE%xsz(2),this%gpE%xsz(3))
   end select

   if (this%useWallmodel) then
       do idx = 1,2
          call this%TestFilter_Cmplx_to_Real(this%tauijWMhat_inY(:,:,:,idx),this%tauijWM_filt(:,:,:,idx))
       end do 
   endif 

   ! Denominator Calculation
   this%buff2 = this%S_ij_E(:,:,:,1)*this%S_ij_E(:,:,:,1)
   do idx = 2,6
      this%buff2 = this%buff2 + this%S_ij_E(:,:,:,idx)*this%S_ij_E(:,:,:,idx)
   end do
   this%buff2 = this%buff2*this%Dsgs
   call this%TestFilter_Real_to_Real_ip(this%buff2)
   
   this%buff1 = this%Sij_filt(:,:,:,1)*this%Sij_filt(:,:,:,1)
   do idx = 2,6
      this%buff1 = this%buff1 + this%Sij_filt(:,:,:,idx)*this%Sij_filt(:,:,:,idx)
   end do
   this%buff1 = this%buff1*this%Dsgs_filt
   this%buff1 = (this%deltaRat*this%deltaRat)*this%buff1
   this%buff2 = this%buff2 - this%buff1

   ! Numerator Calculation
   this%buff1 = uE*this%fiE(:,:,:,1)
   this%buff1 = this%buff1 + vE*this%fiE(:,:,:,2)
   this%buff1 = this%buff1 + wE*this%fiE(:,:,:,3)
  
   if (.not. this%isInviscid) then
      do idx = 1,9
         this%buff1 = this%buff1 - (1.d0/this%Re)*duidxjE(:,:,:,idx)*duidxjE(:,:,:,idx)
      end do 
   end if
   if (this%useWallmodel) then
         this%buff1 = this%buff1 + this%tauijWM(:,:,:,1)*this%S_ij_E(:,:,:,3) 
         this%buff1 = this%buff1 + this%tauijWM(:,:,:,2)*this%S_ij_E(:,:,:,5) 
   end if
   call this%TestFilter_Real_to_Real_ip(this%buff1)
   
   do idx = 1,3
      this%buff1 = this%buff1 - this%ui_filt(:,:,:,idx)*this%fi_filt(:,:,:,idx)
   end do 
  
   if (.not. this%isInviscid) then
      do idx = 1,9
         this%buff1 = this%buff1 + (1.d0/this%Re)*this%alphaij_filt(:,:,:,idx)*this%alphaij_filt(:,:,:,idx)
      end do 
   end if
   if (this%useWallmodel) then
         this%buff1 = this%buff1 - this%tauijWM_filt(:,:,:,1)*this%Sij_filt(:,:,:,3) 
         this%buff1 = this%buff1 - this%tauijWM_filt(:,:,:,2)*this%Sij_filt(:,:,:,5) 
   end if

   !print '(6(i5,1x))', nrank, this%gpE%xst(3), this%gpE%xen(3), this%gpE%xsz(3), this%gpE%zsz(3), nz_global
   ! first and last CV in z is half the CVs in the center
   if(this%gpE%xst(3) == 1) then
     this%buff1(:,:,1) = half*this%buff1(:,:,1)
     this%buff2(:,:,1) = half*this%buff2(:,:,1)
   endif
   if(this%gpE%xen(3) == this%gpE%zsz(3)) then
     this%buff1(:,:,this%gpE%xsz(3)) = half*this%buff1(:,:,this%gpE%xsz(3))
     this%buff2(:,:,this%gpE%xsz(3)) = half*this%buff2(:,:,this%gpE%xsz(3))
   endif

   num = p_sum(this%buff1)
   den = p_sum(this%buff2) 

   this%cmodel_global = 0.5d0*max(num/(den+1.0D-15),0.d0)
   write(*,*) this%cmodel_global
end subroutine


subroutine interp_bForce_CellToEdge(this)
   class(sgs_igrid), intent(inout) :: this

   call transpose_x_to_y(this%fxC, this%rbuffyC(:,:,:,1), this%gpC)
   call transpose_y_to_z(this%rbuffyC(:,:,:,1), this%rbuffzC(:,:,:,1), this%gpC)
   call this%PadeDer%interpz_C2E(this%rbuffzC(:,:,:,1), this%rbuffzE(:,:,:,1), 0, 0)
   call transpose_z_to_y(this%rbuffzE(:,:,:,1), this%rbuffyE(:,:,:,1), this%gpE)
   call transpose_y_to_x(this%rbuffyE(:,:,:,1), this%fiE(:,:,:,1), this%gpE)

   call transpose_x_to_y(this%fyC, this%rbuffyC(:,:,:,1), this%gpC)
   call transpose_y_to_z(this%rbuffyC(:,:,:,1), this%rbuffzC(:,:,:,1), this%gpC)
   call this%PadeDer%interpz_C2E(this%rbuffzC(:,:,:,1), this%rbuffzE(:,:,:,1), 0, 0)
   call transpose_z_to_y(this%rbuffzE(:,:,:,1), this%rbuffyE(:,:,:,1), this%gpE)
   call transpose_y_to_x(this%rbuffyE(:,:,:,1), this%fiE(:,:,:,2), this%gpE)

   this%fiE(:,:,:,3) = this%fzE ! I can't figure out a way to avoid this stupid copy

end subroutine
