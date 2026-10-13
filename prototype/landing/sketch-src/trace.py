import sys, json, numpy as np
from PIL import Image, ImageDraw
from skimage import measure, filters, color, morphology
IMG='../img/era%d-full.jpg'
EXT={'vermeer':'../img/room-era5-vermeer.jpg','starry':'../img/room-era7-vangogh.jpg','wander':'../img/room-era6-friedrich.jpg','mondrian':'../img/room-era8-mondrian.jpg','parthenon':'../img/room-era2-parthenon.jpg','pyramid':'../img/room-era1-pyramid.jpg','notredame':'../img/room-era3-notredame.jpg'}

def chaikin(p, n=2):
    for _ in range(n):
        q=[p[0]]
        for a,b in zip(p[:-1],p[1:]):
            q.append(.75*a+.25*b); q.append(.25*a+.75*b)
        q.append(p[-1]); p=np.array(q)
    return p

def run(cfg):
    im=Image.open(EXT[cfg['era']] if isinstance(cfg['era'],str) else IMG%cfg['era']).convert('RGB')
    W,H=im.size
    x,y,w,h=cfg['crop']  # normalized
    box=(int(x*W),int(y*H),int((x+w)*W),int((y+h)*H))
    c=im.crop(box); S=cfg.get('size',600)
    c=c.resize((S,int(S*c.size[1]/c.size[0])),Image.LANCZOS)
    a=np.asarray(c).astype(float)/255
    vbw=140; k=vbw/S; vbh=c.size[1]*k
    paths=[]; global colors; colors={}
    from scipy import ndimage
    def occupancy():
        m=Image.new('L',(c.size[0],c.size[1]),0); dr=ImageDraw.Draw(m)
        for p in paths:
            if isinstance(p,tuple): continue
            dr.line([tuple(q/k) for q in p],fill=255,width=2)
        return ndimage.distance_transform_edt(np.asarray(m)==0)
    for L in cfg['layers']:
        dist=occupancy() if L.get('avoid') else None
        ch=L.get('ch','lum')
        if ch=='lum': g=color.rgb2gray(a)
        elif ch=='sat': g=color.rgb2hsv(a)[...,1]
        elif ch=='hue': g=color.rgb2hsv(a)[...,0]
        elif ch in 'rgb': g=a[...,'rgb'.index(ch)]
        elif ch=='lab_b': g=(color.rgb2lab(a)[...,2]+60)/120
        elif ch=='lab_a': g=(color.rgb2lab(a)[...,1]+60)/120
        g=filters.gaussian(g,L.get('blur',4))
        gy,gx=np.gradient(g); gm=np.hypot(gx,gy)
        for lv in L['levels']:
            cs=measure.find_contours(g,lv)
            if L.get('edge'):   # keep only runs where the edge is strong: open strokes instead of blobs
                thr=np.percentile(gm,L['edge']); runs=[]
                for cn in cs:
                    v=gm[np.clip(cn[:,0].astype(int),0,g.shape[0]-1),np.clip(cn[:,1].astype(int),0,g.shape[1]-1)]>thr
                    st=None
                    for i,ok in enumerate(list(v)+[False]):
                        if ok and st is None: st=i
                        if not ok and st is not None: runs.append(cn[st:i]); st=None
                cs=runs
            if dist is not None:
                runs=[]
                for cn in cs:
                    v=dist[np.clip(cn[:,0].astype(int),0,g.shape[0]-1),np.clip(cn[:,1].astype(int),0,g.shape[1]-1)]>L['avoid']
                    st=None
                    for i,ok in enumerate(list(v)+[False]):
                        if ok and st is None: st=i
                        if not ok and st is not None: runs.append(cn[st:i]); st=None
                cs=runs
            for cn in cs:
                if len(cn)<2: continue
                ln=np.sum(np.hypot(*np.diff(cn,axis=0).T))
                if ln<L.get('minlen',60): continue
                cn=measure.approximate_polygon(cn,L.get('eps',1.5))
                cn=chaikin(cn[:,::-1],2)*k
                paths.append(cn)
    u=vbw/100.0
    for st in cfg.get('hand',[]):
        if isinstance(st,dict) and 'poly' in st:
            paths.append(np.array(st['poly'],float)*u); colors[len(paths)-1]=st.get('c'); continue
        if isinstance(st,dict) and 'circle' in st:
            cx,cy,r=st['circle']; t=np.linspace(0,2*np.pi,41)
            paths.append(np.stack([cx+r*np.cos(t),cy+r*np.sin(t)],1)*u); continue
        if isinstance(st,str):   # raw svg path in crop units
            import re
            paths.append(('raw', re.sub(r'-?\d+\.?\d*', lambda m: f'{float(m.group())*u:.1f}', st))); continue
        P=np.array(st,float)*u
        if len(P)>2:
            P=np.vstack([P[0],P,P[-1]]); out=[]
            for i in range(1,len(P)-2):
                p0,p1,p2,p3=P[i-1],P[i],P[i+1],P[i+2]
                for t in np.linspace(0,1,8,endpoint=False):
                    t2,t3=t*t,t*t*t
                    out.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3))
            out.append(P[-2]); P=np.array(out)
        paths.append(P)
    return c,paths,vbw,vbh

def todsvg(p):
    p=measure.approximate_polygon(np.asarray(p),0.12)
    return 'M'+'L'.join(f'{x:.1f} {y:.1f}' for x,y in p)

if __name__=='__main__':
    cfgs=json.load(open(sys.argv[1]))
    out={}
    for name,cfg in cfgs.items():
        c,paths,vbw,vbh=run(cfg)
        ds=[p[1] if isinstance(p,tuple) else todsvg(p) for p in paths]
        cols=[colors.get(i) for i in range(len(ds))]
        out[name]={'vb':[round(vbw,1),round(vbh,1)],'d':[[d,c] if c else d for d,c in zip(ds,cols)]}
        # previews
        sc=4; cw,chh=int(vbw*sc),int(vbh*sc)
        bg=c.resize((cw,chh)); ov=Image.blend(Image.new('RGB',(cw,chh),'white'),bg,.35)
        line=Image.new('RGB',(cw,chh),'white')
        svgs=''.join(f'<path d="{d}"'+(f' stroke="{c}"' if c else '')+'/>' for d,c in zip(ds,cols))
        open(f'./out/{name}.svg','w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vbw:.1f} {vbh:.1f}" width="{cw}" height="{chh}"><g fill="none" stroke="#4a4741" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke">{svgs}</g></svg>')
        (Image.open(cfg['gridbg']).resize((cw,chh)) if cfg.get('gridbg') else bg).save(f'./out/{name}_bg.png')
        print(name, len(ds), 'paths', sum(len(d) for d in ds),'chars')
    json.dump(out,open('./out/out.json','w'))
