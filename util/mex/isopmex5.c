#include <math.h>
#include <stdio.h>
#include "mex.h"
#include "opnml_mex5_allocs.c"

/* PROTOTYPES */
void isophase(int,
              double *,
              double *,
              int *,
              double *,
              double,
              double **,
              int *,
              double);

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

/* ---- isopmex will be called as :
        mat=isopmex(x,y,e,q,cval); 
[e,x,y,z,b]=loadgrid('nsea2ll');                                     
[data,gname]=read_s2r;
q=data(:,2);                        
                                      ------------------------------- */
   int cnt,*ele,i,j,nn,ne;
   double *x, *y, *q;
   double *cval,*dele;
   double **cmat,*newcmat;
   int nrl,nrh,ncl,nch;
   double NaN=mxGetNaN(); 
     
/* ---- check I/O arguments ----------------------------------------- */
   if (nrhs != 5) 
      mexErrMsgTxt("isophase_mex requires 5 input arguments.");
   else if (nlhs !=1) 
      mexErrMsgTxt("isophase_mex requires 1 output arguments.");

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
   ele=(int *)mxIvector(0,3*ne-1);
   for (i=0;i<3*ne;i++) ele[i]=((int)dele[i]-1);
   
/* ---- allocate space for divergence list dv following 
        NRC allocation style                            
   cmat= mxDmatrix(     0,     ne-1,    0,      3)     -------------- */

   nrl=0;
   nrh=6*ne;
   ncl=0;
   nch=3;
   cmat=(double **) mxDmatrix(nrl,nrh,ncl,nch);
        
   isophase(ne,x,y,ele,q,cval[0],cmat,&cnt,NaN); 
   
   if (cnt<1){
      plhs[0]=mxCreateDoubleMatrix(0,0,mxREAL); 
      return; 
   }     
    
   newcmat=(double *) mxDvector(0,2*cnt-1);
   for (j=0;j<2;j++)
      for (i=0;i<cnt;i++)
         newcmat[cnt*j+i]=cmat[i][j];

   /* 
   Set elements of return matrix, pointed to by plhs[0]
   */
   plhs[0]=mxCreateDoubleMatrix(cnt,2,mxREAL); 
   mxSetPr(plhs[0],newcmat);

   /*
   No need to free memory allocated with "mxCalloc"; MATLAB does
   this auotmatically.  The CMEX allocation functions in 
   "opnml_allocs.c" use mxCalloc.   
   */ 
   
   return;   
}

/****************************************************************

  ###    #####  ####### ######  #     #    #     #####  #######
   #    #     # #     # #     # #     #   # #   #     # #
   #    #       #     # #     # #     #  #   #  #       #
   #     #####  #     # ######  ####### #     #  #####  #####
   #          # #     # #       #     # #######       # #
   #    #     # #     # #       #     # #     # #     # #
  ###    #####  ####### #       #     # #     #  #####  #######

****************************************************************/
   
#ifdef __STDC__
   void isophase(int ne,
        	 double *x, 
        	 double *y,
        	 int *ele,
        	 double *pha,
        	 double cval,
        	 double **cmat,
        	 int *cnt,
        	 double NaN)
#else
   void isophase(ne,x,y,ele,pha,cval,cmat,cnt,NaN)
   int ne;
   double *x, *y, *pha,cval,**cmat,NaN;
   int *ele,*cnt;
#endif
#define ELE(i,j,m) ele[i+m*j]
// #define DEBUG 
{
   double var[9],xx[9],yy[9];
   double plmt=150.,p0lmt=260.,xp[6],yp[6];
   int i,icnt,k,k2,l,n,count,nsw,nvert=3;
   int n0,n1,n2;
   double vlmt,v1,v3,xcon,ycon;
   bool test;
   
   count=0;
   
   for(l=0;l<ne;l++){                  /* begin 651 */
       
      n0=ELE(l,0,ne);
      n1=ELE(l,1,ne);
      n2=ELE(l,2,ne);  
      /* if element contains a NaN, ignore this element */
      test=(mxIsNaN(pha[n0]) | mxIsNaN(pha[n1]) | mxIsNaN(pha[n2]));
      if (test){continue;}

#ifdef DEBUG
//        if ((l % 1000)==0){
//        if (l == 0){
//           printf(" L = %d\n",l);
//        }
         if(l==10){
            /* */ 
            test=(mxIsNaN(pha[n0]) | mxIsNaN(pha[n1]) | mxIsNaN(pha[n2]));
            if (test){continue;}
            printf("%d %f %d %d ... \n",n0,pha[n0],mxIsNaN(pha[n0]),test);
            printf("%d %f %d ... \n",n1,pha[n1],mxIsNaN(pha[n1]));
            printf("%d %f %d ... \n",n2,pha[n2],mxIsNaN(pha[n2]));            
            /* */ 
         }
#endif

      nsw=0;
      for(k=0;k<nvert;k++){            /* begin 641 */
         n=ELE(l,k,ne);
         xx[k]=x[n];
         yy[k]=y[n];
         var[k]=pha[n];
         vlmt=plmt;         

         if(cval<1.){
            vlmt=p0lmt;
            if(var[k]>180.) var[k]=var[k]-360.;
         }
      }                                /* end 641 */
   
      if(cval==var[0]) {
         nsw=1;
         icnt=1;
         xp[icnt]=xx[0];
         yp[icnt]=yy[0];
      }
      for(k=0;k<nvert;k++){                /* begin 649 */
         k2=k+1;
         if(k2>nvert-1) k2=0;
         if(var[k]>var[k2]) goto L610;
         if(cval<var[k]||cval>var[k2]) goto L649;
         goto L611;
 L610:   if(cval<var[k2]||cval>var[k]) goto L649;
 L611:   v3=var[k2]-var[k];
         if(fabs(v3)>vlmt) goto L649;
         v1=1.;
         if(fabs(v3)>1.e-7) v1=(cval-var[k])/v3;
         xcon=v1*(xx[k2]-xx[k])+xx[k];
         ycon=v1*(yy[k2]-yy[k])+yy[k];
         if(nsw==1) {
            icnt++;
            xp[icnt]=xcon;
            yp[icnt]=ycon;
         }
         else{
            nsw=1;
            icnt=1;
            xp[icnt]=xcon;
            yp[icnt]=ycon;
         }
 L649:continue;
      }                                  /* end 649 */
      if(nsw==1&&icnt>1) {
         for(i=1;i<=icnt;i++){
            cmat[count][0]=xp[i];
            cmat[count][1]=yp[i];
            count++;
         }
         cmat[count][0]=NaN;   /* this puts a break in the plotted line */
         cmat[count][1]=NaN;
         count++;        
      }
   }                                    /* end 651 */
   *cnt=count;
   return;
}
