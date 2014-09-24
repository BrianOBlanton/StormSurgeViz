#include <math.h>
#include <stdio.h>
#include "mex.h"
#include "opnml_mex5_allocs.c"

/* PROTOTYPES */
void isopts(int,
            double *,
            double *,
            int *,
            double *,
            double,
            double **,
            int *);

/************************************************************

  ####     ##     #####  ######  #    #    ##     #   #
 #    #   #  #      #    #       #    #   #  #     # #
 #       #    #     #    #####   #    #  #    #     #
 #  ###  ######     #    #       # ## #  ######     #
 #    #  #    #     #    #       ##  ##  #    #     #
  ####   #    #     #    ######  #    #  #    #     #

************************************************************/

void mexFunction(int            nlhs,
                 mxArray       *plhs[],
		 int            nrhs,
		 const mxArray *prhs[])
{

/* ---- contmex5 will be called as :
        cmat=contmex5(x,y,ele,q,cval); ---------------------------- */

   int cnt,*ele,i,j,nn,ne;
   double *x, *y, *q;
   double *cval,*dele;
   double **cmat,*newcmat;
   int nrl,nrh,ncl,nch ;
     
/* ---- check I/O arguments ----------------------------------------- */
   if (nrhs != 5) 
      mexErrMsgTxt("contmex5 requires 5 input arguments.");
   else if (nlhs != 1) 
      mexErrMsgTxt("contmex5 requires 1 output arguments.");

/* ---- dereference input arrays ------------------------------------ */
   x=mxGetPr(prhs[0]);
   y=mxGetPr(prhs[1]);
   dele=mxGetPr(prhs[2]);
   q=mxGetPr(prhs[3]);
   cval=mxGetPr(prhs[4]);
   nn=mxGetM(prhs[0]);
   ne=mxGetM(prhs[2]);   
   

/* ---- allocate space for int representation of dele &
        convert double element representation to int  &
        shift node numbers toward 0 by 1 for proper indexing -------- */
   ele=(int *)mxIvector(0,3*ne);
   for (i=0;i<3*ne;i++)
      ele[i]=((int)dele[i])-1;
   
/* ---- allocate space for contour list cmat following NRC 
        allocation style
        double **mxDmatrix(int nrl,int nrh,int ncl,int nch)
        cmat= mxDmatrix(     0,     ne-1,    0,      3) ------------- */
   nrl=0;
   nrh=6*ne;
   ncl=0;
   nch=3;
   cmat=(double **) mxDmatrix(nrl,nrh,ncl,nch);
  
   isopts(ne,x,y,ele,q,cval[0],cmat,&cnt); 
   
   if(cnt!=0){
      newcmat=(double *) mxDvector(0,4*cnt-1);
      for (j=0;j<4;j++)
	 for (i=0;i<cnt;i++)
            newcmat[cnt*j+i]=cmat[i][j];
      /* ---- Set elements of return matrix, pointed to by plhs[0] -------- */
      plhs[0]=mxCreateDoubleMatrix(cnt,4,mxREAL); 
      mxFree(mxGetPr(plhs[0])); 
      mxSetPr(plhs[0],newcmat);
   }
   else {
      plhs[0]=mxCreateDoubleMatrix(1,1,mxREAL); 
      mxFree(mxGetPr(plhs[0])); 
      mxSetPr(plhs[0],NULL);  
   }
         
/* ---- No need to free memory allocated with "mxCalloc"; MATLAB 
   does this automatically.  The CMEX allocation functions in 
   "opnml_allocs.c" use mxCalloc. ----------------------------------- */ 
   return;   
}

/*----------------------------------------------------------------------

    #     ####    ####   #####    #####   ####
    #    #       #    #  #    #     #    #
    #     ####   #    #  #    #     #     ####
    #         #  #    #  #####      #         #
    #    #    #  #    #  #          #    #    #
    #     ####    ####   #          #     ####

----------------------------------------------------------------------*/
   
#ifdef __STDC__
   void isopts(int ne,
               double *x, double *y,
               int *ele,double *q,
               double cval,
               double **cmat,int *cnt)
#else
   void isopts(ne,x,y,ele,q,cval,cmat,cnt)
   int ne;
   double *x, *y, *q,cval,**cmat;
   int *ele,*cnt;
#endif
#define ELE(i,j,m) ele[i+m*j]
#define TOL 1.e-10
{

/* ---- ELE is defined to perform the following array 
        element extraction     ELE(i,j,m) ele[i+m*j] ---------------- */
   int count=0,k;
   int n0,n1,n2;
   double s0,s1,s2;
   double xa,xb,ya,yb;
   double fac;
   double x0,x1,x2;
   double y0,y1,y2;
   
/* ---- Element loop to determine contours -------------------------- */
   for(k=0;k<ne;k++){
   
/* ---- First arrange element k nodes such that n0,n1,n2 => s0<s1<s2 -*/   
      n0=ELE(k,0,ne);
      s0=q[n0];
      n1=ELE(k,1,ne);
      s1=q[n1];
      if (s1<s0){
         n0=n1;
         s0=s1;
         n1=ELE(k,0,ne);
         s1=q[n1];
      }
      n2=ELE(k,2,ne);
      s2=q[n2];
      if (s2<s1){
         n2=n1;
         s2=s1;
         n1=ELE(k,2,ne);
         s1=q[n1];
         if(s1<s0){
            n1=n0;
            s1=s0;
            n0=ELE(k,2,ne);
            s0=q[n0];
         }
      }
      x0=x[n0];
      y0=y[n0];
      x1=x[n1];
      y1=y[n1];
      x2=x[n2];
      y2=y[n2];
      
      if(cval<s0)goto L10;   /* cval < element min ------------------ */
      if(cval>s2)goto L10;   /* cval > element max ------------------ */
      
      if (fabs(s0-s1)<TOL&&          /*  Contour on side n0 -> n1 --- */
          fabs(s0-cval)<TOL){           
         cmat[count][0]=x0;      
         cmat[count][1]=y0;
         cmat[count][2]=x1;
         cmat[count][3]=y1;
         count++;
      }
      else if (fabs(s1-s2)<TOL&&     /*  Contour on side n1 -> n2 --- */
               fabs(s1-cval)<TOL){           
         cmat[count][0]=x1;      
         cmat[count][1]=y1; 
         cmat[count][2]=x2;
         cmat[count][3]=y2;
         count++;
      }
      else if (fabs(s0-s2)<TOL&&     /*  Contour on side n2 -> n0 --- */
               fabs(s2-cval)<TOL){           
         cmat[count][0]=x2;      
         cmat[count][1]=y2; 
         cmat[count][2]=x0;
         cmat[count][3]=y0;
         count++;
      }
      else if (fabs(s0-s2)<TOL){    /*  Contour over entire element - */
         cmat[count][0]=x0;
         cmat[count][1]=y0;
         cmat[count][2]=x1;
         cmat[count][3]=y1;
         count++;
         cmat[count][0]=x1;
         cmat[count][1]=y1;
         cmat[count][2]=x2;
         cmat[count][3]=y2;
         count++;
         cmat[count][0]=x2;
         cmat[count][1]=y2;
         cmat[count][2]=x0;
         cmat[count][3]=y0;
         count++;
      }
      else {                        /*  Contour within  element ----- */
         fac=(cval-s0)/(s2-s0);
         xa=x0+(x2-x0)*fac;
         ya=y0+(y2-y0)*fac;
         if(cval<s1){
            if(s0!=s1) fac=(cval-s0)/(s1-s0);
            else fac=1.0;
            xb=x0+(x1-x0)*fac;
            yb=y0+(y1-y0)*fac;
         }
         else{
            if(s1!=s2) fac=(cval-s1)/(s2-s1);
            else fac=1.0;
            xb=x1+(x2-x1)*fac;
            yb=y1+(y2-y1)*fac;
         } 
         cmat[count][0]=xa;
         cmat[count][1]=ya;
         cmat[count][2]=xb;
         cmat[count][3]=yb;
         count++;
      }
      L10: continue;
   }
   *cnt=count;
   return;
}

   
   
   
   
   
