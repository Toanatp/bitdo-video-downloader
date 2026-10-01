from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
root=Path(r'D:\Tool_All\Tool_Free\Youtube_Download\bitdo-video-downloader')
out=root/'public'/'product'/'batch-download.png'
W,H=1200,760
img=Image.new('RGB',(W,H),(13,14,19))
d=ImageDraw.Draw(img)
try:
    font_big=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',44)
    font_med=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',26)
    font_sm=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
    font_bold=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',24)
except Exception:
    font_big=font_med=font_sm=font_bold=None
# top nav
nav_h=82
d.rectangle([0,0,W,nav_h], fill=(22,23,29))
d.rounded_rectangle([28,20,70,54], radius=8, fill=(232,232,235))
d.polygon([(43,29),(43,45),(58,37)], fill=(22,23,29))
d.text((86,24),'Bitdo Downloader', fill=(235,238,245), font=font_bold)
# active tab
pill=[430,18,620,62]
d.rounded_rectangle(pill, radius=25, fill=(28,84,68))
d.text((472,30),'Downloads', fill=(108,240,194), font=font_sm)
d.text((680,30),'Batch Queue', fill=(168,173,185), font=font_sm)
d.text((965,30),'Settings', fill=(168,173,185), font=font_sm)
# hero/title
accent=(104,231,189)
d.text((46,116),'Batch Video Download Queue', fill=(245,247,252), font=font_big)
d.text((48,170),'Paste many video links, process them in one queue, and track every download in real time.', fill=(172,178,191), font=font_med)
# input panel
panel=[44,220,W-44,330]
d.rounded_rectangle(panel, radius=18, fill=(25,26,33), outline=(52,54,64), width=2)
d.text((74,246),'Batch URL List', fill=(235,238,245), font=font_bold)
d.text((74,282),'13 links detected  •  YouTube, TikTok, Facebook, Vimeo, SoundCloud...', fill=(155,163,176), font=font_sm)
d.rounded_rectangle([880,250,1108,302], radius=24, fill=accent)
d.text((930,263),'Start Batch', fill=(6,18,18), font=font_bold)
# queue header
left=44; top=365; right=W-44
d.text((left,top-38),'Downloading 4 / 13', fill=(245,247,252), font=font_bold)
d.rounded_rectangle([250, top-42, 340, top-12], radius=14, fill=(23,54,72))
d.text((270, top-38),'Batch', fill=(122,205,245), font=font_sm)
items=[
 ('YouTube','Beautiful Landscape 4K','1080p mp4','86%',0.86,(65,145,245)),
 ('TikTok','Short Product Demo','720p mp4','63%',0.63,(124,95,235)),
 ('Facebook','Marketing Reel Collection','1080p mp4','41%',0.41,(49,142,255)),
 ('SoundCloud','Chill Music Mix','320kbps mp3','100%',1.0,(40,205,125)),
]
for idx,(plat,title,fmt,pct,prog,color) in enumerate(items):
    y=top+idx*88
    d.rounded_rectangle([left,y,right,y+70], radius=14, fill=(25,26,33), outline=(52,54,64), width=1)
    d.rounded_rectangle([left+18,y+14,left+88,y+56], radius=10, fill=color)
    d.text((left+108,y+12), title, fill=(242,244,249), font=font_bold)
    d.text((left+108,y+42), f'{plat}  •  {fmt}', fill=(155,163,176), font=font_sm)
    bar_x=550; bar_y=y+30; bar_w=430
    d.rounded_rectangle([bar_x,bar_y,bar_x+bar_w,bar_y+12], radius=6, fill=(64,67,77))
    d.rounded_rectangle([bar_x,bar_y,bar_x+int(bar_w*prog),bar_y+12], radius=6, fill=(104,190,232) if prog<1 else accent)
    d.text((1005,y+22), pct, fill=(226,232,240), font=font_sm)
    d.rounded_rectangle([1060,y+20,1100,y+58], radius=12, fill=(38,40,48))
    d.text((1073,y+27),'Ⅱ', fill=(226,232,240), font=font_sm)
# completed panel
base=top+len(items)*88+20
d.rounded_rectangle([left,base,right,base+86], radius=16, fill=(17,34,28), outline=(44,108,86), width=1)
d.text((left+26,base+22),'Completed: 9 videos saved to Downloads/Bitdo Batch', fill=(132,239,199), font=font_bold)
d.text((left+26,base+54),'Auto retry, pause/resume, and queue progress are visible in one screen.', fill=(166,178,186), font=font_sm)
img.save(out)
print(out)
