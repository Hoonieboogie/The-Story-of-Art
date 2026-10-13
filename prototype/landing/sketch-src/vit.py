import sys; sys.path.insert(0,'.')
from skel import *
im=Image.open('../img/era4-vitruvian.jpg').convert('RGB'); W,H=im.size
x0,y0,x1,y1=[int(v) for v in (100/699*W,195/950*H,600/699*W,695/950*H)]
c=im.crop((x0,y0,x1,y1)); S=520; c=c.resize((S,S),Image.LANCZOS)
a=np.asarray(c)/255.
g=color.rgb2gray(a)
bg=filters.gaussian(g,12); ink=(bg-filters.gaussian(g,1.5))>float(sys.argv[1])
m=6; ink[:m,:]=0; ink[-14:,:]=0; ink[:,:m]=0; ink[:,-m:]=0
ink=morphology.remove_small_objects(ink,max_size=60)
ink=morphology.closing(ink,morphology.disk(2))
sk=morphology.skeletonize(ink)
ps=[p for p in trace_skeleton(sk) if len(p)>4]
ps=merge(ps,4)
ps=[p for p in ps if np.sum(np.hypot(*np.diff(p,axis=0).T))>float(sys.argv[2])]
print(len(ps))
circ=lambda k,X,Y: (lambda cx,cy,r: f'M{cx-r:.1f} {cy:.1f}a{r:.1f} {r:.1f} 0 1 0 {2*r:.1f} 0a{r:.1f} {r:.1f} 0 1 0 {-2*r:.1f} 0')((262-X)*k,(214-Y)*k,311*k)
sq=lambda k,X,Y: f'M{(2-X)*k:.1f} {(2-Y)*k:.1f}H{(S-2-X)*k:.1f}V{(S-2-Y)*k:.1f}H{(2-X)*k:.1f}Z'
import math
def ell(cx,cy,rx,ry,wav=0,n=9,a0=0,a1=2*math.pi):
    def f(k,X,Y):
        pts=[]
        for i in range(73):
            t=a0+(a1-a0)*i/72; r=1+wav*math.sin(n*t)
            pts.append(((cx+rx*r*math.cos(t)-X)*k,(cy+ry*r*math.sin(t)-Y)*k))
        return 'M'+'L'.join(f'{x:.1f} {y:.1f}' for x,y in pts)
    return f
face=ell(261,50,19,27,a0=0.15*math.pi,a1=0.85*math.pi+math.pi)  # open oval
hair=ell(261,40,34,40,wav=.07,n=11,a0=-1.15*math.pi,a1=0.18*math.pi)
to_svg(ps,(-56,-104,580,532),[circ,sq,face,hair],'vit',c)
