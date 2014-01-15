#include <math.h>
#include <stdio.h>
#include "mex.h"
#include "opnml_mex5_allocs.c"

/************************************************************

  ####     ##     #####  ######  #    #    ##     #   #
 #    #   #  #      #    #       #    #   #  #     # #
 #       #    #     #    #####   #    #  #    #     #
 #  ###  ######     #    #       # ## #  ######     #
 #    #  #    #     #    #       ##  ##  #    #     #
  ####   #    #     #    ######  #    #  #    #     #

************************************************************/

/* ---- AA,BB,TT are defined to perform the following array 
        element extractions     AA(i,j,m) AA[i+m*j] ---------------- */
#define AA(i,j,m) A[i+m*j]
#define BB(i,j,m) B[i+m*j]
#define TT(i,j,m) T[i+m*j]

void mexFunction(int            nlhs,
                 mxArray       *plhs[],
		 int            nrhs,
		 const mxArray *prhs[])
{

/* ---- findelemex will be called as :
        j_el=findelemex(xp,yp,AR,A,B,T); ---------------------------- */
/* ---- xp,yp are NOT nodal coordinates; they are the points we are 
        finding elements for.  Nodal coordinates have already been 
        accounted for in A,B,T                                      ----- */

   int ip,j,np,nl,nh,ne;
   double *xp, *yp;
   double *AR,*A,*B,*T;
   double *fnd;
   double NaN=mxGetNaN();
   double fac,S1,S2,S3,ONE,ZERO;
   double tol,*tolerance;

     
/* ---- check I/O arguments ----------------------------------------- */
   if (nrhs != 7) 
      mexErrMsgTxt("findelemex requires 7 input arguments.");
   else if (nlhs != 1) 
      mexErrMsgTxt("findelemex requires 1 output arguments.");

/* ---- dereference input arrays ------------------------------------ */
   xp       =mxGetPr(prhs[0]);
   yp       =mxGetPr(prhs[1]);
   AR       =mxGetPr(prhs[2]);
   A        =mxGetPr(prhs[3]);
   B        =mxGetPr(prhs[4]);
   T        =mxGetPr(prhs[5]);
   tolerance=mxGetPr(prhs[6]);

   tol=tolerance[0];
   
   np=mxGetM(prhs[0]);
   ne=mxGetM(prhs[2]);   
   
/* ---- allocate space for list containing element numbers following NRC 
        allocation style
        double *mxDvector(int nl,int nh)
        fnd= (double *) mxDvector(0,np); ---------------------------- */
   fnd= (double *) mxDvector(0,np);
   for (ip=0;ip<np;ip++)fnd[ip]=-1.;
   ONE=1.+tol;
   ZERO=0.-tol;
   for (j=0;j<ne;j++){
      for (ip=0;ip<np;ip++){  
         if(fnd[ip]<(double)0){
            fac=.5/AR[j];         
            S1=(TT(j,0,ne)+BB(j,0,ne)*xp[ip]+AA(j,0,ne)*yp[ip])*fac;
            if (S1>ONE|S1<ZERO)goto l20;
            S2=(TT(j,1,ne)+BB(j,1,ne)*xp[ip]+AA(j,1,ne)*yp[ip])*fac;
            if (S2>ONE|S2<ZERO)goto l20;
            S3=(TT(j,2,ne)+BB(j,2,ne)*xp[ip]+AA(j,2,ne)*yp[ip])*fac;
            if (S3>ONE|S3<ZERO)goto l20;         
            fnd[ip]=(double)(j+1);            
         }
       l20: continue;
       }
    }
    for (ip=0;ip<np;ip++) if(fnd[ip]<(double)0)fnd[ip]=NaN;
               
/* ---- Set elements of return matrix, pointed to by plhs[0] -------- */
   plhs[0]=mxCreateDoubleMatrix(np,1,mxREAL); 
   mxSetPr(plhs[0],fnd);

/* ---- No need to free memory allocated with "mxCalloc"; MATLAB 
   does this automatically.  The CMEX allocation functions in 
   "opnml_allocs.c" use mxCalloc. ----------------------------------- */ 
   return;   
}
