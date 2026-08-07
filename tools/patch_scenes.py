#!/usr/bin/env python3
import os,re,sys
ROOT=sys.argv[1] if len(sys.argv)>1 else "."
MAIN="scenes/main_3d.tscn"
DDIR="scenes/districts"
CANON=["suburbs","residential","park","school","hospital","gas_station","police","warehouses","industrial","substation","power_station"]
EXT=[
("res://scripts/visual/night_env.gd","Night"),
("res://scripts/ui/hud_main.gd","HUD"),
("res://scripts/ui/ending_screen.gd","Ending"),
("res://scripts/net/lan_menu.gd","LANMenu"),
("res://scripts/world/power_switch.gd","PSwitch"),
("res://scripts/world/district_trigger.gd","DTrig"),
("res://scripts/visual/emissive_windows.gd","EWin"),
]
def free_id(text):
    ids=[]
    for m in re.finditer(r'id="(\d+)',text):
        try: ids.append(int(m.group(1)))
        except: pass
    return (max(ids)+1) if ids else 100
def add_ext(text,rp,hint):
    if rp in text: return text,None
    nid="%d_%s"%(free_id(text),hint)
    block='[ext_resource type="Script" path="'+rp+'" id="'+nid+'"]\n'
    idx=text.find("[node ")
    if idx<0: text+=block
    else: text=text[:idx]+block+text[idx:]
    return text,nid
def find_ext(text,rp):
    m=re.search(r'path="'+re.escape(rp)+'"[^]]*id="([^"]+)"',text)
    if not m: m=re.search(r'id="([^"]+)"[^]]*path="'+re.escape(rp)+'"',text)
    return m.group(1) if m else None
def add_node(text,name,parent,tp,rp,extra=""):
    if '[node name="'+name+'"' in text: return text
    eid=find_ext(text,rp)
    if not eid: return text
    blk='\n[node name="'+name+'" type="'+tp+'" parent="'+parent+'"]\nscript = ExtResource("'+eid+'")\n'+extra
    return text+blk
def patch_main(path):
    if not os.path.isfile(path): return
    with open(path,"r",encoding="utf-8") as f: text=f.read()
    changed=False
    for rp,h in EXT: t,_=add_ext(text,rp,h); 
        if t!=text: text=t; changed=True
    for name,tp,rp in [("NightEnv","Node3D",EXT[0][0]),("HUD","CanvasLayer",EXT[1][0]),
        ("EndingScreen","CanvasLayer",EXT[2][0]),("LANMenu","CanvasLayer",EXT[3][0])]:
        t2=add_node(text,name,".",tp,rp); 
        if t2!=text: text=t2; changed=True
    if changed:
        with open(path,"w",encoding="utf-8") as f: f.write(text)
        print("[patch] main saved")
def patch_district(path,did):
    if not os.path.isfile(path): return
    with open(path,"r",encoding="utf-8") as f: text=f.read()
    changed=False
    for rp,h in EXT: t,_=add_ext(text,rp,h); 
        if t!=text: text=t; changed=True
    for name,tp,rp,ex in [("PowerSwitch","Node3D",EXT[4][0],'district_id = "'+did+'"\n'),
        ("DistrictTrigger","Area3D",EXT[5][0],'district_id = "'+did+'"\n'),
        ("EmissiveWindows","MultiMeshInstance3D",EXT[6][0],'seed_value = '+str(abs(hash(did))%99999)+'\n')]:
        t2=add_node(text,name,".",tp,rp,ex); 
        if t2!=text: text=t2; changed=True
    if changed:
        with open(path,"w",encoding="utf-8") as f: f.write(text)
        print("[patch] "+did+" saved")
def main(root):
    patch_main(os.path.join(root,MAIN))
    dd=os.path.join(root,DDIR)
    if not os.path.isdir(dd): os.makedirs(dd,exist_ok=True)
    for d in CANON: patch_district(os.path.join(dd,d+".tscn"),d)
    print("[patch] done")
if __name__=="__main__": main(ROOT)