/*----------------------------------------------------------------------

  MATLAB C-MEX file functions:
  
  Allocation functions have been added for C-MEX function
  writing.  These routines are prefixed with "mx" and are
  available for int and double vector and matrix
  allocation.  There is no "float" capability.
  
  This is the file opnml_mex5_allocs.c, routines for allocation of
  vectors and matricies for use in MATLAB/C-MEX files.  It must
  be complied with strict ANSI-compliance ("gcc -ansi ...", for 
  example, and is coded only for MATLAB5.1 or greater.  It should be
  placed in the OPNML/MATLAB mex src directory, and is included in 
  c-source as:
  
  #include "opnml_mex5_allocs.c"
  
  These routines are taken from Numerical Recipes in C,
  Press et. al., and turned into MATLAB-style allocation routines
  by Brian Blanton (UNC). 
  
  mxCalloc is used to allocate memory.  This function clears
  the allocated space to (double)0.  "Free" functions have NOT been
  added because MATLAB frees memory allocated within a mex
  function automatically upon exit if it has been allocated with
  mxCalloc functions. In fact, freeing memory allocated with mxCalloc 
  within the function seems to cause (atleast me) problems.
  
  The MATLAB header file "mex.h" must have been "included" in
  the c source BEFORE "opnml_mex5_allocs.c".
  Therefore,  the order of "includes" should look something like:
  
  #include <stdio.h>
  #include <math.h>
  #include "mex.h"
  #include "opnml_mex5_allocs.c"
  ...
  
  If you do not, cmex will NOT complain, but you will get a runtime 
  (in MATLAB) error similar to the following:

  /lib/dld.sl: Unresolved symbol: mxfree_Dmatrix (code)  from
     /home5/blanton/matlab/mex/contmex.mexhp7 
  /lib/dld.sl: Unresolved symbol: mxDmatrix (code)  from
     /home5/blanton/matlab/mex/contour_mex.mexhp7 
  Unable to load mex
     file: /home5/blanton/matlab/mex/contmex.mexhp7. 
  ??? Invalid MEX-file
   
  Recall that "matrix.h" is included by "mex.h", so don't do it here. 
  mxCalloc and mxFree WILL BE RESOLVED!!
    
--------------------------------------------------------------------- */
  
#ifndef _OPNML_ALLOCS_INCLUDED
#define _OPNML_ALLOCS_INCLUDED

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int imaxarg1,imaxarg2;
#define IMAX(a,b) (imaxarg1=(a),imaxarg2=(b),(imaxarg1) > (imaxarg2) ? (imaxarg1) : (imaxarg2))
static int iminarg1,iminarg2;
#define IMIN(a,b) (iminarg1=(a),iminarg2=(b),(iminarg1) < (iminarg2) ? (iminarg1) : (iminarg2))


static double dmaxarg1,dmaxarg2;
#define DMAX(a,b) (dmaxarg1=(a),dmaxarg2=(b),(dmaxarg1) > (dmaxarg2) ? (dmaxarg1) : (dmaxarg2))

static double dminarg1,dminarg2;
#define DMIN(a,b) (dminarg1=(a),dminarg2=(b),(dminarg1) < (dminarg2) ? (dminarg1) : (dminarg2))

/* NRC DEFINITION */
#define BUMP 1
#define NR_END 1
#define FREE_ARG char*

/* ---------------------------------------------------------------------

  ####           #    #  ######  #    #
 #    #          ##  ##  #        #  #
 #       ######  # ## #  #####     ##
 #       ######  #    #  #         ##
 #    #          #    #  #        #  #
  ####           #    #  ######  #    #
  
--------------------------------------------------------------------- */
#ifdef mex_h
/* ---- C-MEX ALLOCATION FUNCTION PROTOTYPES ------------------------- */
int     *mxIvector(int nl,int nh);
int    **mxImatrix(int nrl,int nrh,int ncl,int nch);
double  *mxDvector(int nl,int nh);
double **mxDmatrix(int nrl,int nrh,int ncl,int nch);

/* ---- C-MEX INTEGER VECTOR ALLOCATION ------------------------------ */
int *mxIvector(int nl,int nh)
{
   int *v; 
 
   v=(int *)mxCalloc((nh-nl+1),sizeof(int));
   if (!v) {
      puts("allocation failure in mxIvector()");
      return(0);
   }
   return v-nl;
}

/* ---- C-MEX INTEGER MATRIX ALLOCATION ------------------------------ */
int **mxImatrix(int nrl,int nrh,int ncl,int nch)
{
   int i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
   int **m;

   /* allocate pointers to rows */
   m=(int **) mxCalloc(nrow,sizeof(int*));
   if (!m){ 
      puts("row allocation failure in mxImatrix()");
      return(0);
   }
   m -= nrl;

   /* allocate rows and set pointers to them */
   m[nrl]=(int *) mxCalloc(nrow*ncol,sizeof(int));
   if (!m[nrl]) {
      puts("column allocation failure in mxImatrix()");
      return(0);
   }
   m[nrl] -= ncl;

   for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;

   /* return pointer to array of pointers to rows */
   return m;
}

/* ---- C-MEX DOUBLE VECTOR ALLOCATION ------------------------------- */
   double *mxDvector(int nl,int nh)
{
   double *v;

   v=(double *) mxCalloc((nh-nl+1),sizeof(double));
   if (!v) {
      puts("allocation failure in mxDvector()");
      return(0);
   }
   return v-nl;
}

/* ---- C-MEX DOUBLE MATRIX ALLOCATION ------------------------------- */
double **mxDmatrix(int nrl,int nrh,int ncl,int nch)
{
   int i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
   double **m;

   /* allocate pointers to rows */
   m=(double **) mxCalloc(nrow,sizeof(double*));
   if (!m) {
      puts("row allocation failure in mxDmatrix()");
      return(0);
   }
   m -= nrl;

   /* allocate rows and set pointers to them */
   m[nrl]=(double *) mxCalloc(nrow*ncol,sizeof(double));
   if (!m[nrl]) {
      puts("column allocation failure in mxDmatrix()");
      return(0);
   }
   m[nrl] -= ncl;

   for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;

   /* return pointer to array of pointers to rows */
   return m;
}


/* ---------------------------------------------------------------------

  ####    #####  #    #  ######  #####
 #    #     #    #    #  #       #    #
 #    #     #    ######  #####   #    #
 #    #     #    #    #  #       #####
 #    #     #    #    #  #       #   #
  ####      #    #    #  ######  #    #

--------------------------------------------------------------------- */
void opnmlerror0(char *error_text)
{
   fprintf(stderr,"%s\n",error_text);
   exit(-1);
} 

void opnmlerror(char *error_text,char *routine_name,int line_number,int error_code)
{
	fprintf(stderr,"%s\n",error_text);
	fprintf(stderr,"Routine: %s\n",routine_name);
	fprintf(stderr,"Line Number: %d\n",line_number);
	fprintf(stderr,"INTERNAL ERROR CODE: %d\n\n",error_code);
	
	exit(error_code);
} 

void opnmlerror2(char *error_text,char *routine_name,int error_code)
{
   int i,line_number=0,nrow;
   nrow=sizeof(error_text)/sizeof(char *);

   for (i=0;i<nrow;i++)
     fprintf(stderr,"%s",error_text[i]);
   
   fprintf(stderr,"Routine: %s\n",routine_name);
   /*fprintf(stderr,"Line Number: %d\n",line_number);*/
   fprintf(stderr,"INTERNAL ERROR CODE: %d\n\n",error_code);
   
   exit(error_code);
} 

void nrerror(char error_text[])
/* Numerical Recipes standard error handler */
{
        fprintf(stderr,"Numerical Recipes run-time error...\n");
        fprintf(stderr,"%s\n",error_text);
        fprintf(stderr,"...now exiting to system...\n");
        exit(1);
}
int *Ivector(long nl, long nh)
/* allocate an int vector with subscript range v[nl..nh] */
{
        int *v;
        v=(int *)malloc((size_t) ((nh-nl+1+BUMP)*sizeof(int)));
        if (!v) nrerror("allocation failure in ivector()");
        return v-nl+BUMP;
}
void free_Ivector(int *v, long nl, long nh)
/* free an int vector allocated with ivector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

#endif  /* mex_h */

#endif  /* _OPNML_ALLOCS_INCLUDED */
