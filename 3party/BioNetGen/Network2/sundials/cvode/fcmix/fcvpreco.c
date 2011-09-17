/*
 * -----------------------------------------------------------------
 * $Revision: 1.12.2.3 $
 * $Date: 2005/04/06 23:32:53 $
 * ----------------------------------------------------------------- 
 * Programmers: Alan C. Hindmarsh and Radu Serban @ LLNL
 * -----------------------------------------------------------------
 * Copyright (c) 2002, The Regents of the University of California.
 * Produced at the Lawrence Livermore National Laboratory.
 * All rights reserved.
 * For details, see sundials/cvode/LICENSE.
 * -----------------------------------------------------------------
 * The C function FCVPSet is to interface between the CVSPGMR module
 * and the user-supplied preconditioner setup routine FCVPSET.
 * Note the use of the generic name FCV_PSET below.
 * -----------------------------------------------------------------
 */

#include <stdio.h>
#include <stdlib.h>

#include "cvspgmr.h"        /* CVSpgmr prototype                              */
#include "fcvode.h"         /* actual function names, prototypes and
			       global variables                               */
#include "nvector.h"        /* definitions of type N_Vector and vector macros */
#include "sundialstypes.h"  /* definition of type realtype                    */

/*********************************************************************/

/* Prototype of the Fortran routines */

#ifdef __cplusplus  /* wrapper to enable C++ usage */
extern "C" {
#endif
  extern void FCV_PSET(realtype*, realtype*, realtype*, booleantype*, 
                       booleantype*, realtype*, realtype*, realtype*,
                       realtype*, realtype*, realtype*, int*);
  extern void FCV_PSOL(realtype*, realtype*, realtype*, realtype*, 
                       realtype*, realtype*, realtype*, 
                       realtype*, int*, realtype*, int*);
#ifdef __cplusplus
}
#endif

/***************************************************************************/

void FCV_SPGMRSETPREC(int *flag, int *ier)
{
  if (*flag == 0) CVSpgmrSetPreconditioner(CV_cvodemem, NULL, NULL, NULL);
  else CVSpgmrSetPreconditioner(CV_cvodemem, FCVPSet, FCVPSol, NULL);
}

/***************************************************************************/

/* C function FCVPSet to interface between CVODE and a Fortran subroutine
   FCVPSET for setup of a Krylov preconditioner.
   Addresses of Nlocal, t, jok, gamma, h, uround, y, fy, ewt, vtemp1, vtemp2, 
   vtemp3, and the address jcurPtr are passed to FCVPSET, using
   the routine N_VGetArrayPointer from NVECTOR.  A return flag ier from FCVPSET
   is returned by FCVPSet.
   Auxiliary data is assumed to be communicated by common blocks. */

int FCVPSet(realtype t, N_Vector y, N_Vector fy, booleantype jok,
            booleantype *jcurPtr, realtype gamma,
            void *P_data,
            N_Vector vtemp1, N_Vector vtemp2, N_Vector vtemp3)
{
  N_Vector ewt;
  realtype h;
  realtype *ydata, *fydata, *ewtdata, *v1data, *v2data, *v3data;

  int ier = 0;
  
  ewt = N_VClone(y);

  CVodeGetErrWeights(CV_cvodemem, ewt);
  CVodeGetLastStep(CV_cvodemem, &h);

  ydata   = N_VGetArrayPointer(y);
  fydata  = N_VGetArrayPointer(fy);
  ewtdata = N_VGetArrayPointer(ewt);
  v1data  = N_VGetArrayPointer(vtemp1);
  v2data  = N_VGetArrayPointer(vtemp2);
  v3data  = N_VGetArrayPointer(vtemp3);

  FCV_PSET(&t, ydata, fydata, &jok, jcurPtr, &gamma, ewtdata,
           &h, v1data, v2data, v3data, &ier);

  N_VDestroy(ewt);

  return(ier);
}

/***************************************************************************/

/* C function FCVPSol to interface between CVODE and a Fortran subroutine
   FCVPSOL for solution of a Krylov preconditioner.
   Addresses of t, gamma, delta, lr, y, fy, vtemp, ewt, r, and z are
   passed to FCVPSOL, using the routine N_VGetArrayPointer from NVECTOR.
   A return flag ier from FCVPSOL is returned by FCVPSol.
   Auxiliary data is assumed to be communicated by Common blocks. */

int FCVPSol(realtype t, N_Vector y, N_Vector fy, 
            N_Vector r, N_Vector z,
            realtype gamma, realtype delta,
            int lr, void *P_data, N_Vector vtemp)
{
  N_Vector ewt;
  realtype *ydata, *fydata, *vtdata, *ewtdata, *rdata, *zdata;

  int ier = 0;

  ewt = N_VClone(y);

  CVodeGetErrWeights(CV_cvodemem, ewt);

  ydata   = N_VGetArrayPointer(y);
  fydata  = N_VGetArrayPointer(fy);
  vtdata  = N_VGetArrayPointer(vtemp);
  ewtdata = N_VGetArrayPointer(ewt);
  rdata   = N_VGetArrayPointer(r);
  zdata   = N_VGetArrayPointer(z);

  FCV_PSOL(&t, ydata, fydata, vtdata, &gamma, ewtdata, &delta,
           rdata, &lr, zdata, &ier);

  N_VDestroy(ewt);

  return(ier);
}
