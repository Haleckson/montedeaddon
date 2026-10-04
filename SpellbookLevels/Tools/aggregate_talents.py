import json,sys,collections
rows=json.load(open(sys.argv[1],encoding="utf8"))
groups=collections.defaultdict(list)
for b in rows: groups[(b["class"],b["spec"])].append(b)
out={}
for (cls,spec),builds in groups.items():
    picks=collections.defaultdict(list)
    for b in builds:
        seen=set()
        for t in b.get("talents",[]):
            nid=int(t["nodeID"])
            if nid not in seen:
                picks[nid].append(float(t.get("rank",1))); seen.add(nid)
    dest={"sample":len(builds),"nodes":{}}
    for nid,ranks in picks.items():
        dest["nodes"][str(nid)]={"selectionPct":round(100*len(ranks)/len(builds),1),
          "avgRank":round(sum(ranks)/len(ranks),2),"sample":len(builds)}
    out.setdefault(cls,{})[spec]=dest
json.dump(out,open(sys.argv[2],"w",encoding="utf8"),indent=2,sort_keys=True)
