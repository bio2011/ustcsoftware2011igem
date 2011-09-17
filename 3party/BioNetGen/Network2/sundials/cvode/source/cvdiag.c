/*
 * -----------------------------------------------------------------
 * $Revision: 1.13 $
 * $Date: 2004/11/06 01:01:51 $
 * ----------------------------------------------------------------- 
 * Programmer(s): Scott D. Cohen, Alan C. Hindmarsh and
 *                Radu Serban @ LLNL
 * -----------------------------------------------------------------
 * Copyright (c) 2002, The Regents of the University of California.
 * Produced at the Lawrence Livermore National Laboratory.
 * All rights reserved.
 * For details, see sundials/cvode/LICENSE.
 * -----------------------------------------------------------------
 * This is the implementation file for the CVDIAG linear solver.
 * -----------------------------------------------------------------
 */

#include <stdio.h>
#include <stdlib.h>

#include "cvdiag_impl.h"
#include "cvode_impl.h"

/* Other Constants */
  
#define FRACT RCONST(0.1)
#define ONE   RCONST(1.0)

/* CVDIAG linit, lsetup, lsolve, and lfree routines */

static int CVDiagInit(CVodeMem cv_mem);

static int CVDiagSetup(CVodeMem cv_mem, int convfail, N_Vector ypred,
                       N_Vector fpred, booleantype *jcurPtr, N_Vector vtemp1,
                       N_Vector vtemp2, N_Vector vtemp3);

static int CVDiagSolve(CVodeMem cv_mem, N_Vector b, N_Vector weight,
                       N_Vector ycur, N_Vector fcur);

static void CVDiagFree(CVodeMem cv_mem);

/* Readability Replacements */

#define lrw1      (cv_mem->cv_lrw1)
#define liw1      (cv_mem->cv_liw1)
#define f         (cv_mem->cv_f)
#define f_data    (cv_mem->cv_f_data)
#define uround    (cv_mem->cv_uround)
#define tn        (cv_mem->cv_tn)
#define h         (cv_mem->cv_h)
#define rl1       (cv_mem->cv_rl1)
#define gamma     (cv_mem->cv_gamma)
#define ewt       (cv_mem->cv_ewt)
#define nfe       (cv_mem->cv_nfe)
#define errfp     (cv_mem->cv_errfp)
#define zn        (cv_mem->cv_zn)
#define linit     (cv_mem->cv_linit)
#define lsetup    (cv_mem->cv_lsetup)
#define lsolve    (cv_mem->cv_lsolve)
#define lfree     (cv_mem->cv_lfree)
#define lmem      (cv_mem->cv_lmem)
#define vec_tmpl  (cv_mem->cv_tempv)
#define setupNonNull   (cv_mem->cv_setupNonNull)

#define gammasv   (cvdiag_mem->di_gammasv)
#define M         (cvdiag_mem->di_M)
#define bit       (cvdiag_mem->di_bit)
#define bitcomp   (cvdiag_mem->di_bitcomp)
#define nfeDI     (cvdiag_mem->di_nfeDI)
#define last_flag (cvdiag_mem->di_last_flag)

/*
 * -----------------------------------------------------------------
 * CVDiag 
 * -----------------------------------------------------------------
 * This routine initializes the memory record and sets various function
 * fields specific to the diagonal linear solver module.  CVDense first
 * calls the existing lfree routine if this is not NULL.  Then it sets
 * the cv_linit, cv_lsetup, cv_lsolve, cv_lfree fields in (*cvode_mem)
 * to be CVDiagInit, CVDiagSetup, CVDiagSolve, and CVDiagFree,
 * respectively.  It allocates memory for a structure of type
 * CVDiagMemRec and sets the cv_lmem field in (*cvode_mem) to the
 * address of this structure.  It sets setupNonNull in (*cvode_mem) to
 * TRUE.  Finally, it allocates memory for M, bit, and bitcomp.
 * The CVDiag return value is SUCCESS = 0, LMEM_FAIL = -1, or 
 * LIN_ILL_INPUT=-2.
 * -----------------------------------------------------------------
 */
  
int CVDiag(void *cvode_mem)
{
  CVodeMem cv_mem;
  CVDiagMem cvdiag_mem;

  /* Return immediately if cvode_mem is NULL */
  if (cvode_mem == NULL) {
    fprintf(stderr, MSGDG_CVMEM_NULL);
    return(CVDIAG_MEM_NULL);
  }
  cv_mem = (CVodeMem) cvode_mem;

  /* Check if N_VCompare and N_VInvTest are present */
  if(vec_tmpl->ops->nvcompare == NULL ||
     vec_tmpl->ops->nvinvtest == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_BAD_NVECTOR);
    return(CVDIAG_ILL_INPUT);
  }

  if (lfree != NULL) lfree(cv_mem);
  
  /* Set four main function fields in cv_mem */
  linit  = CVDiagInit;
  lsetup = CVDiagSetup;
  lsolve = CVDiagSolve;
  lfree  = CVDiagFree;

  /* Get memory for CVDiagMemRec */
  cvdiag_mem = (CVDiagMem) malloc(sizeof(CVDiagMemRec));
  if (cvdiag_mem == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_MEM_FAIL);
    return(CVDIAG_MEM_FAIL);
  }

  last_flag = CVDIAG_SUCCESS;

  /* Set flag setupNonNull = TRUE */
  setupNonNull = TRUE;

  /* Allocate memory for M, bit, and bitcomp */
    
  M = N_VClone(vec_tmpl);
  if (M == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_MEM_FAIL);
    return(CVDIAG_MEM_FAIL);
  }
  bit = N_VClone(vec_tmpl);
  if (bit == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_MEM_FAIL);
    N_VDestroy(M);
    return(CVDIAG_MEM_FAIL);
  }
  bitcomp = N_VClone(vec_tmpl);
  if (bitcomp == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_MEM_FAIL);
    N_VDestroy(M);
    N_VDestroy(bit);
    return(CVDIAG_MEM_FAIL);
  }

  /* Attach linear solver memory to integrator memory */
  lmem = cvdiag_mem;

  return(CVDIAG_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * CVDiagGetWorkSpace
 * -----------------------------------------------------------------
 */

int CVDiagGetWorkSpace(void *cvode_mem, long int *lenrwDI, long int *leniwDI)
{
  CVodeMem cv_mem;

  /* Return immediately if cvode_mem is NULL */
  if (cvode_mem == NULL) {
    fprintf(stderr, MSGDG_SETGET_CVMEM_NULL);
    return(CVDIAG_MEM_NULL);
  }
  cv_mem = (CVodeMem) cvode_mem;

  *lenrwDI = 3*lrw1;
  *leniwDI = 3*liw1;

  return(CVDIAG_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * CVDiagGetNumRhsEvals
 * -----------------------------------------------------------------
 */

int CVDiagGetNumRhsEvals(void *cvode_mem, long int *nfevalsDI)
{
  CVodeMem cv_mem;
  CVDiagMem cvdiag_mem;

  /* Return immediately if cvode_mem is NULL */
  if (cvode_mem == NULL) {
    fprintf(stderr, MSGDG_SETGET_CVMEM_NULL);
    return(CVDIAG_MEM_NULL);
  }
  cv_mem = (CVodeMem) cvode_mem;

  if (lmem == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_SETGET_LMEM_NULL);
    return(CVDIAG_LMEM_NULL);
  }
  cvdiag_mem = (CVDiagMem) lmem;

  *nfevalsDI = nfeDI;

  return(CVDIAG_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * CVDiagGetLastFlag
 * -----------------------------------------------------------------
 */

int CVDiagGetLastFlag(void *cvode_mem, int *flag)
{
  CVodeMem cv_mem;
  CVDiagMem cvdiag_mem;

  /* Return immediately if cvode_mem is NULL */
  if (cvode_mem == NULL) {
    fprintf(stderr, MSGDG_SETGET_CVMEM_NULL);
    return(CVDIAG_MEM_NULL);
  }
  cv_mem = (CVodeMem) cvode_mem;

  if (lmem == NULL) {
    if(errfp!=NULL) fprintf(errfp, MSGDG_SETGET_LMEM_NULL);
    return(CVDIAG_LMEM_NULL);
  }
  cvdiag_mem = (CVDiagMem) lmem;

  *flag = last_flag;

  return(CVDIAG_SUCCESS);
}

/*
 * -----------------------------------------------------------------
 * CVDiagInit
 * -----------------------------------------------------------------
 * This routine does remaining initializations specific to the diagonal
 * linear solver.
 * -----------------------------------------------------------------
 */

static int CVDiagInit(CVodeMem cv_mem)
{
  CVDiagMem cvdiag_mem;

  cvdiag_mem = (CVDiagMem) lmem;

  nfeDI = 0;

  last_flag = CVDIAG_SUCCESS;
  return(0);
}

/*
 * -----------------------------------------------------------------
 * CVDiagSetup
 * -----------------------------------------------------------------
 * This routine does the setup operations for the diagonal linear 
 * solver.  It constructs a diagonal approximation to the Newton matrix 
 * M = I - gamma*J, updates counters, and inverts M.
 * -----------------------------------------------------------------
 */

static int CVDiagSetup(CVodeMem cv_mem, int convfail, N_Vector ypred,
                       N_Vector fpred, booleantype *jcurPtr, N_Vector vtemp1,
                       N_Vector vtemp2, N_Vector vtemp3)
{
  realtype r;
  N_Vector ftemp, y;
  booleantype invOK;
  CVDiagMem cvdiag_mem;
  
  cvdiag_mem = (CVDiagMem) lmem;

  /* Rename work vectors for use as temporary values of y and f */
  ftemp = vtemp1;
  y     = vtemp2;

  /* Form y with perturbation = FRACT*(func. iter. correction) */
  r = FRACT * rl1;
  N_VLinearSum(h, fpred, -ONE, zn[1], ftemp);
  N_VLinearSum(r, ftemp, ONE, ypred, y);

  /* Evaluate f at perturbed y */
  f(tn, y, M, f_data);
  nfeDI++;

  /* Construct M = I - gamma*J with J = diag(deltaf_i/deltay_i) */
  N_VLinearSum(ONE, M, -ONE, fpred, M);
  N_VLinearSum(FRACT, ftemp, -h, M, M);
  N_VProd(ftemp, ewt, y);
  /* Protect against deltay_i being at roundoff level */
  N_VCompare(uround, y, bit);
  N_VAddConst(bit, -ONE, bitcomp);
  N_VProd(ftemp, bit, y);
  N_VLinearSum(FRACT, y, -ONE, bitcomp, y);
  N_VDiv(M, y, M);
  N_VProd(M, bit, M);
  N_VLinearSum(ONE, M, -ONE, bitcomp, M);

  /* Invert M with test for zero components */
  invOK = N_VInvTest(M, M);
  if (!invOK) {
    last_flag = CVDIAG_INV_FAIL;
    return(1);
  }

  /* Set jcur = TRUE, save gamma in gammasv, and return */
  *jcurPtr = TRUE;
  gammasv = gamma;
  last_flag = CVDIAG_SUCCESS;
  return(0);
}

/*
 * -----------------------------------------------------------------
 * CVDiagSolve
 * -----------------------------------------------------------------
 * This routine performs the solve operation for the diagonal linear
 * solver.  If necessary it first updates gamma in M = I - gamma*J.
 * -----------------------------------------------------------------
 */

static int CVDiagSolve(CVodeMem cv_mem, N_Vector b, N_Vector weight,
                       N_Vector ycur, N_Vector fcur)
{
  booleantype invOK;
  realtype r;
  CVDiagMem cvdiag_mem;

  cvdiag_mem = (CVDiagMem) lmem;
  
  /* If gamma has changed, update factor in M, and save gamma value */

  if (gammasv != gamma) {
    r = gamma / gammasv;
    N_VInv(M, M);
    N_VAddConst(M, -ONE, M);
    N_VScale(r, M, M);
    N_VAddConst(M, ONE, M);
    invOK = N_VInvTest(M, M);
    if (!invOK) {
      last_flag = CVDIAG_INV_FAIL;
      return (1);
    }
    gammasv = gamma;
  }

  /* Apply M-inverse to b */
  N_VProd(b, M, b);

  last_flag = CVDIAG_SUCCESS;
  return(0);
}

/*
 * -----------------------------------------------------------------
 * CVDiagFree
 * -----------------------------------------------------------------
 * This routine frees memory specific to the diagonal linear solver.
 * -----------------------------------------------------------------
 */

static void CVDiagFree(CVodeMem cv_mem)
{
  CVDiagMem cvdiag_mem;
  
  cvdiag_mem = (CVDiagMem) lmem;

  N_VDestroy(M);
  N_VDestroy(bit);
  N_VDestroy(bitcomp);
  free(cvdiag_mem);
}
