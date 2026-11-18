# figs_s129.py  Figs. S2 and S3 of supplement v129 from the scenarios of script 51. Same data and drawing code as figs_s128.py with one presentation change
# (November 18, 2026): the yellow wash over the extrapolated years is replaced by a dashed vertical line where the benchmark record ends, to match Fig. 5 of manuscript v137.
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt, pandas as pd
from matplotlib.lines import Line2D
from matplotlib.patches import Patch
from PIL import Image
EV='/mnt/user-data/uploads/Koa/tools/2026-11-15_v136-build/'; O='/tmp/koa2/figs/'
sc=pd.read_csv(EV+'scenarios_long_j1.csv'); sc['site_dev']=sc['site_dev'].astype(str).str.upper()=='TRUE'
MM=1/25.4; INK='#1B2A49'; OR={0:'#0072B2',1:'#D55E00'}; ORN={0:'Natural',1:'Planted'}; LV={'lo':'#56B4E9','md':'#009E73','hi':'#CC79A7'}; LVN={'lo':'Low BYI','md':'Median BYI','hi':'High BYI'}; SH='#F0E442'
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'axes.edgecolor':INK,'axes.labelcolor':INK,'xtick.color':INK,'ytick.color':INK,'text.color':INK,'axes.labelweight':'bold','axes.linewidth':0.6,'axes.spines.top':False,'axes.spines.right':False,'savefig.facecolor':'white'})
def tag(ax,s): ax.text(0.0,1.03,s,transform=ax.transAxes,fontweight='bold',fontsize=9,va='bottom',ha='left')
fig,axs=plt.subplots(3,2,figsize=(140*MM,170*MM),sharex=True); VL={'RD':'Relative density','HT':'Height (m)','VOL':'Assumed volume (m³ ha⁻¹)'}; k=0
for r,v in enumerate(['RD','HT','VOL']):
    for c,p in enumerate([0,1]):
        ax=axs[r,c]; ax.axvline(33 if p==0 else 10,color=INK,linewidth=0.7,linestyle=(0,(2,2)))
        for lv in ['lo','md','hi']:
            d=sc[(sc.site_dev==False)&(sc['var']==v)&(sc.planted==p)&(sc.level==lv)].sort_values('year')
            ax.fill_between(d.year,d.p05,d.p95,color=LV[lv],alpha=0.16,linewidth=0); ax.plot(d.year,d.point,color=LV[lv],linewidth=1.3)
        if v=='RD':
            ax.axhline(1,color='#D55E00',linewidth=0.8,linestyle=(0,(3,2)))
            if p==0: ax.text(99,1.02,'RD = 1',ha='right',va='bottom',fontsize=8,color='#D55E00')
        ax.set_xlim(0,100); ax.set_ylim(bottom=0)
        if c==0: ax.set_ylabel(VL[v])
        if r==0: ax.set_title(ORN[p],fontsize=9,fontweight='bold',color=INK,pad=10)
        if r==2: ax.set_xlabel('Years from starting measurement')
        tag(ax,'('+'abcdef'[k]+')'); k+=1
h=[Line2D([],[],color=LV[l],linewidth=1.6,label=LVN[l]) for l in ['lo','md','hi']]+[Patch(facecolor=LV['md'],alpha=0.3,label='90% band'),Line2D([],[],color=INK,linewidth=0.7,linestyle=(0,(2,2)),label='Benchmark record ends')]
fig.legend(handles=h,loc='lower center',ncol=5,frameon=False,fontsize=8,handletextpad=0.4,columnspacing=1.0)
fig.tight_layout(rect=(0,0.04,1,1),w_pad=1.0,h_pad=1.0); fig.savefig(O+'FigS2_rd_height_volume.png',dpi=350); plt.close(fig)
fig,axs=plt.subplots(3,2,figsize=(140*MM,170*MM),sharex=True); VL={'BA':'Basal area (m² ha⁻¹)','QMD':'QMD (cm)','TPH':'Stems (ha⁻¹)'}; k=0
for r,v in enumerate(['BA','QMD','TPH']):
    for c,p in enumerate([0,1]):
        ax=axs[r,c]; ax.axvline(33 if p==0 else 10,color=INK,linewidth=0.7,linestyle=(0,(2,2)))
        a=sc[(sc.site_dev==False)&(sc['var']==v)&(sc.planted==p)&(sc.level=='md')].sort_values('year'); b=sc[(sc.site_dev==True)&(sc['var']==v)&(sc.planted==p)&(sc.level=='md')].sort_values('year')
        ax.fill_between(b.year,b.p05,b.p95,color='#CC79A7',alpha=0.28,linewidth=0); ax.fill_between(a.year,a.p05,a.p95,color=OR[p],alpha=0.30,linewidth=0)
        ax.plot(a.year,a.point,color=OR[p],linewidth=1.5); ax.plot(a.year,a.p50,color='#009E73',linewidth=1.1,linestyle=(0,(4,2)))
        ax.set_xlim(0,100); ax.set_ylim(bottom=0)
        if c==0: ax.set_ylabel(VL[v])
        if r==0: ax.set_title(ORN[p],fontsize=9,fontweight='bold',color=INK,pad=10)
        if r==2: ax.set_xlabel('Years from starting measurement')
        tag(ax,'('+'abcdef'[k]+')'); k+=1
h=[Line2D([],[],color=OR[0],linewidth=1.6,label='Point, natural'),Line2D([],[],color=OR[1],linewidth=1.6,label='Point, planted'),Line2D([],[],color='#009E73',linewidth=1.1,linestyle=(0,(4,2)),label='Monte Carlo median'),Patch(facecolor=OR[1],alpha=0.3,label='90% band, SDImax from S1'),Patch(facecolor='#CC79A7',alpha=0.28,label='90% band, SDImax may deviate'),Line2D([],[],color=INK,linewidth=0.7,linestyle=(0,(2,2)),label='Benchmark record ends')]
fig.legend(handles=h,loc='lower center',ncol=3,frameon=False,fontsize=8,handletextpad=0.4,columnspacing=1.0)
fig.tight_layout(rect=(0,0.07,1,1),w_pad=1.0,h_pad=1.0); fig.savefig(O+'FigS3_bands.png',dpi=350); plt.close(fig)
for f in ['FigS2_rd_height_volume.png','FigS3_bands.png']:
    im=Image.open(O+f).convert('RGBA'); bg=Image.new('RGB',im.size,'white'); bg.paste(im,mask=im.split()[3]); bg.save(O+f,dpi=(350,350))
print('ok')
