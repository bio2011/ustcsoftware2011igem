#include <math.h>
#include "mathutils.h"

/* Computes using a Numerical Recipes routine the singular value 
   decomposition of A (mxn matrix) overwriting A with U.  The SVD is A = 
   U.diag(w).Vt  N.B. The w's are NOT sorted. */

static double dpythag(double a, double b);

void SVD(double **aa, int m, int n, double ww[], double **vv){
    int flag,i,its,j,jj,k,l,nm;
    double anorm,c,f,g,h,s,scale,x,y,z,*rv1, *rv;
    double **a, *w, **v;

    /* convert zero offset arrays to unit offset */
    w = ww-1;
    a = ((double **) malloc(m*sizeof(double *))) - 1;
    v = ((double **) malloc(n*sizeof(double *))) - 1 ;
    a[1] = aa[0] - 1;
    v[1] = vv[0] - 1;
    for(i=2; i<=m; ++i)
       a[i] = a[i-1] + n;
    for(i=2; i<=n; ++i)
       v[i] = v[i-1] + n;

    rv=ALLOC_VECTOR(n);
    rv1= rv-1;

    g=scale=anorm=0.0;
    for (i=1;i<=n;i++) {
	l=i+1;
	rv1[i]=scale*g;
	g=s=scale=0.0;
	if (i <= m) {
	    for (k=i;k<=m;k++) scale += fabs(a[k][i]);
	    if (scale) {
		for (k=i;k<=m;k++) {
		    a[k][i] /= scale;
		    s += a[k][i]*a[k][i];
		}
		f=a[i][i];
		g = -SIGN(sqrt(s),f);
		h=f*g-s;
		a[i][i]=f-g;
		for (j=l;j<=n;j++) {
		    for (s=0.0,k=i;k<=m;k++) s += a[k][i]*a[k][j];
		    f=s/h;
		    for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
		}
		for (k=i;k<=m;k++) a[k][i] *= scale;
	    }
	}
	w[i]=scale *g;
	g=s=scale=0.0;
	if (i <= m && i != n) {
	    for (k=l;k<=n;k++) scale += fabs(a[i][k]);
	    if (scale) {
		for (k=l;k<=n;k++) {
		    a[i][k] /= scale;
		    s += a[i][k]*a[i][k];
		}
		f=a[i][l];
		g = -SIGN(sqrt(s),f);
		h=f*g-s;
		a[i][l]=f-g;
		for (k=l;k<=n;k++) rv1[k]=a[i][k]/h;
		for (j=l;j<=m;j++) {
		    for (s=0.0,k=l;k<=n;k++) s += a[j][k]*a[i][k];
		    for (k=l;k<=n;k++) a[j][k] += s*rv1[k];
		}
		for (k=l;k<=n;k++) a[i][k] *= scale;
	    }
	}
	anorm=MAX(anorm,(fabs(w[i])+fabs(rv1[i])));
    }
    for (i=n;i>=1;i--) {
	if (i < n) {
	    if (g) {
		for (j=l;j<=n;j++) v[j][i]=(a[i][j]/a[i][l])/g;
		for (j=l;j<=n;j++) {
		    for (s=0.0,k=l;k<=n;k++) s += a[i][k]*v[k][j];
		    for (k=l;k<=n;k++) v[k][j] += s*v[k][i];
		}
	    }
	    for (j=l;j<=n;j++) v[i][j]=v[j][i]=0.0;
	}
	v[i][i]=1.0;
	g=rv1[i];
	l=i;
    }
    for (i=IMIN(m,n);i>=1;i--) {
	l=i+1;
	g=w[i];
	for (j=l;j<=n;j++) a[i][j]=0.0;
	if (g) {
	    g=1.0/g;
	    for (j=l;j<=n;j++) {
		for (s=0.0,k=l;k<=m;k++) s += a[k][i]*a[k][j];
		f=(s/a[i][i])*g;
		for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
	    }
	    for (j=i;j<=m;j++) a[j][i] *= g;
	} else for (j=i;j<=m;j++) a[j][i]=0.0;
	++a[i][i];
    }
    for (k=n;k>=1;k--) {
	for (its=1;its<=30;its++) {
	    flag=1;
	    for (l=k;l>=1;l--) {
		nm=l-1;
		if ((double)(fabs(rv1[l])+anorm) == anorm) {
		    flag=0;
		    break;
		}
		if ((double)(fabs(w[nm])+anorm) == anorm) break;
	    }
	    if (flag) {
		c=0.0;
		s=1.0;
		for (i=l;i<=k;i++) {
		    f=s*rv1[i];
		    rv1[i]=c*rv1[i];
		    if ((double)(fabs(f)+anorm) == anorm) break;
		    g=w[i];
		    h=dpythag(f,g);
		    w[i]=h;
		    h=1.0/h;
		    c=g*h;
		    s = -f*h;
		    for (j=1;j<=m;j++) {
			y=a[j][nm];
			z=a[j][i];
			a[j][nm]=y*c+z*s;
			a[j][i]=z*c-y*s;
		    }
		}
	    }
	    z=w[k];
	    if (l == k) {
		if (z < 0.0) {
		    w[k] = -z;
		    for (j=1;j<=n;j++) v[j][k] = -v[j][k];
		}
		break;
	    }
	    if (its == 30) MATHERR("SVD:no convergence in 30 dsvdcmp \
iterations",00); 
	    x=w[l];
	    nm=k-1;
	    y=w[nm];
	    g=rv1[nm];
	    h=rv1[k];
	    f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
	    g=dpythag(f,1.0);
	    f=((x-z)*(x+z)+h*((y/(f+SIGN(g,f)))-h))/x;
	    c=s=1.0;
	    for (j=l;j<=nm;j++) {
		i=j+1;
		g=rv1[i];
		y=w[i];
		h=s*g;
		g=c*g;
		z=dpythag(f,h);
		rv1[j]=z;
		c=f/z;
		s=h/z;
		f=x*c+g*s;
		g = g*c-x*s;
		h=y*s;
		y *= c;
		for (jj=1;jj<=n;jj++) {
		    x=v[jj][j];
		    z=v[jj][i];
		    v[jj][j]=x*c+z*s;
		    v[jj][i]=z*c-x*s;
		}
		z=dpythag(f,h);
		w[j]=z;
		if (z) {
		    z=1.0/z;
		    c=f*z;
		    s=h*z;
		}
		f=c*g+s*y;
		x=c*y-s*g;
		for (jj=1;jj<=m;jj++) {
		    y=a[jj][j];
		    z=a[jj][i];
		    a[jj][j]=y*c+z*s;
		    a[jj][i]=z*c-y*s;
		}
	    }
	    rv1[l]=0.0;
	    rv1[k]=f;
	    w[k]=x;
	}
    }
    FREE_VECTOR(rv);
    free(a+1);
    free(v+1);
}

static double dpythag(double a, double b){
   double absa,absb;
   absa=fabs(a);
   absb=fabs(b);
   if (absa > absb) 
      return absa*sqrt(1.0+SQR(absb/absa));
   else 
      return (absb == 0.0 ? 0.0 : absb*sqrt(1.0+SQR(absa/absb)));
}

/* Solves A.x=b following SVD of A = U.diag(w).Vt.  u and v are the svd
   matrices returned by SVD, and w contains the weights.  Values of w below
   some user determined threshold should be set to zero to remove the
   ill-conditioned parts.  No input quantities are altered. */

void SVBKSB( double **u, double w[], double **v, int m, int n, double b[],
	     double x[])
{
    register int i,j,jj;
    double s, *tmp;

    tmp= ALLOC_VECTOR(n);
    for ( j=0; j<n; ++j)
    {
	s=0.0;
	if (w[j])
	{
	    for(i=0; i<m; ++i) s+= u[i][j]*b[i];
	    s /= w[j];
	}
	tmp[j]=s;
    }
    for ( j=0; j<n; ++j)
    {
	s=0.0;
	for(jj=0; jj<n; ++jj) s+= v[j][jj]*tmp[jj];
	x[j]=s;
    }
    FREE_VECTOR(tmp);
}


