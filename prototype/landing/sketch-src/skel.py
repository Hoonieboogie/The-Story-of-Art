import numpy as np, json, sys
from PIL import Image
from skimage import color, filters, morphology, measure
def chaikin(p, n=2):
    for _ in range(n):
        q=[p[0]]
        for a,b in zip(p[:-1],p[1:]): q.append(.75*a+.25*b); q.append(.25*a+.75*b)
        q.append(p[-1]); p=np.array(q)
    return p
def trace_skeleton(sk):
    # pixel graph walk: returns list of polylines (row,col)
    H,W=sk.shape; pts=set(zip(*np.nonzero(sk)))
    nb=lambda p:[(p[0]+dy,p[1]+dx) for dy in (-1,0,1) for dx in (-1,0,1) if (dy or dx) and (p[0]+dy,p[1]+dx) in pts]
    deg={p:len(nb(p)) for p in pts}
    used=set(); paths=[]
    def walk(a,b):
        path=[a,b]; used.add(frozenset((a,b)))
        while deg[path[-1]]==2:
            nx=[q for q in nb(path[-1]) if frozenset((path[-1],q)) not in used]
            if not nx: break
            used.add(frozenset((path[-1],nx[0]))); path.append(nx[0])
        return path
    for p in pts:
        if deg[p]!=2:
            for q in nb(p):
                if frozenset((p,q)) not in used: paths.append(walk(p,q))
    for p in pts:  # loops
        for q in nb(p):
            if frozenset((p,q)) not in used: paths.append(walk(p,q))
    return [np.array(p,float) for p in paths]
def merge(paths, tol=3.0):
    # greedily join paths whose ends touch, preferring smooth continuation
    paths=[p for p in paths]; changed=True
    while changed:
        changed=False
        for i in range(len(paths)):
            for j in range(i+1,len(paths)):
                a,b=paths[i],paths[j]
                for A,B in ((a,b),(a,b[::-1]),(a[::-1],b),(a[::-1],b[::-1])):
                    if np.hypot(*(A[-1]-B[0]))<=tol:
                        da=A[-1]-A[max(0,len(A)-6)]; db=B[min(len(B)-1,5)]-B[0]
                        na,nb_=np.linalg.norm(da),np.linalg.norm(db)
                        if na and nb_ and np.dot(da,db)/(na*nb_)>0.5:
                            paths[i]=np.vstack([A,B[1:]]); paths.pop(j); changed=True; break
                if changed: break
            if changed: break
    return paths

def to_svg(paths, bounds, extra=(), name='x', bgimg=None, bgbox=None):
    # paths in crop pixel (row,col); bounds=(x0,y0,x1,y1) in crop px -> viewBox 140 wide
    x0,y0,x1,y1=bounds; k=140/(x1-x0); vbh=(y1-y0)*k
    ds=[]
    for p in paths:
        p=measure.approximate_polygon(p,1.0); p=chaikin(p[:,::-1],2)
        p=(p-[x0,y0])*k
        ds.append('M'+'L'.join(f'{a:.1f} {b:.1f}' for a,b in p))
    for e in extra: ds.append(e(k,x0,y0))
    svg=lambda w,h:f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 {vbh:.1f}" width="{w}" height="{h}"><g fill="none" stroke="#3d3a35" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke">'+''.join(f'<path d="{d}" vector-effect="non-scaling-stroke"/>' for d in ds)+'</g></svg>'
    open(f'./out/{name}.svg','w').write(svg(560,int(560*vbh/140)))
    open(f'./out/{name}_small.svg','w').write(svg(140,int(140*vbh/140)))
    if bgimg is not None:
        cw,ch=560,int(560*vbh/140); can=Image.new('RGB',(cw,ch),'white')
        bx0,by0=(0-x0)*k*4,(0-y0)*k*4
        b=bgimg.resize((int(bgimg.size[0]*k*4),int(bgimg.size[1]*k*4))); can.paste(b,(int(bx0),int(by0)))
        Image.blend(Image.new('RGB',(cw,ch),'white'),can,.35).save(f'./out/{name}_bg.png')
    json.dump({'vb':[140,round(vbh,1)],'d':ds},open(f'./out/{name}.json','w'))
    return ds
