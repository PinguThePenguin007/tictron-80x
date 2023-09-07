-- title:   3D Portals demo
-- author:  nequ16
-- desc:    a proof of concept 3D FPS demo where you're able to place a pair of portals that you can see and walk through (kinda)
-- license: MIT License
-- version: 0.1
-- script:  lua

t=0

function sin(angle) return math.sin(math.rad(angle)) end
function cos(angle) return math.cos(math.rad(angle)) end

function addP(a,b)	return {x=a.x+b.x,y=a.y+b.y,z=a.z+b.z} end
function subP(a,b)	return {x=a.x-b.x,y=a.y-b.y,z=a.z-b.z} end
function mulP(a,k)	return {x=a.x*k,y=a.y*k,z=a.z*k} end
function lerp(a,b,k)
	if a.u and b.u then	return {x=a.x+(b.x-a.x)*k,y=a.y+(b.y-a.y)*k,z=a.z+(b.z-a.z)*k,u=a.u+(b.u-a.u)*k,v=a.v+(b.v-a.v)*k}
	else	return {x=a.x+(b.x-a.x)*k,y=a.y+(b.y-a.y)*k,z=a.z+(b.z-a.z)*k}	end
end

function getNormal(a,b,c)
	local va={x=a.x-b.x,y=a.y-b.y,z=a.z-b.z}
	local vb={x=c.x-b.x,y=c.y-b.y,z=c.z-b.z}
	local n={}
	n.x=va.y*vb.z-va.z*vb.y
	n.y=va.z*vb.x-va.x*vb.z
	n.z=va.x*vb.y-va.y*vb.x
	return n
end

function getCross(a,b)
	return {x=a.y*b.z-a.z*b.y,y=a.z*b.x-a.x*b.z,z=a.x*b.y-a.y*b.x}
end

function getDot(a,b)
	return a.x*b.x+a.y*b.y+a.z*b.z
end

function getLen(v)
	return math.sqrt(v.x^2+v.y^2+v.z^2)
end

function normalize(v)
	return {x=v.x/getLen(v),y=v.y/getLen(v),z=v.z/getLen(v)}
end

function movePoint(p,d)
	return {x=p.x+d.x,y=p.y+d.y,z=p.z+d.z,u=p.u,v=p.v}
end

function rotatePoint(p,d)
	local temp={x=p.x,y=p.y,z=p.z,u=p.u,v=p.v}
	temp.x,temp.z=temp.x*cos(-d.y)-temp.z*sin(-d.y),temp.x*sin(-d.y)+temp.z*cos(-d.y)
	temp.y,temp.z=temp.y*cos(-d.x)-temp.z*sin(-d.x),temp.y*sin(-d.x)+temp.z*cos(-d.x)
	temp.x,temp.y=temp.x*cos(-d.z)-temp.y*sin(-d.z),temp.x*sin(-d.z)+temp.y*cos(-d.z)
	return temp
end

function scalePoint(p,d)
	return {x=p.x*d.x,y=p.y*d.y,z=p.z*d.z,u=p.u,v=p.v}
end

function transformCam(p)
	local temp={x=p.x-cam.pos.x,y=p.y-cam.pos.y,z=p.z-cam.pos.z}
	temp.x,temp.y=temp.x*cos(cam.rot.z)-temp.y*sin(cam.rot.z),temp.x*sin(cam.rot.z)+temp.y*cos(cam.rot.z)
	temp.y,temp.z=temp.y*cos(cam.rot.x)-temp.z*sin(cam.rot.x),temp.y*sin(cam.rot.x)+temp.z*cos(cam.rot.x)
	temp.x,temp.z=temp.x*cos(cam.rot.y)-temp.z*sin(cam.rot.y),temp.x*sin(cam.rot.y)+temp.z*cos(cam.rot.y)
	return temp
end

function getTri(objTable,conId)
	return {a=objTable.ver[objTable.con[conId].a],b=objTable.ver[objTable.con[conId].b],c=objTable.ver[objTable.con[conId].c]}
end

function rayTriInt(p,r)
	local e1=subP(p.b,p.a)
	local e2=subP(p.c,p.a)
	local pvec=getCross(r.n,e2)
	local det=getDot(e1,pvec)
	if math.abs(det)<1e-8 then return false end
	local inv_det=1/det
	local tvec=subP(r.p,p.a)
	local u=getDot(tvec,pvec)*inv_det
	if u<0 or u>1 then return false end
	local qvec=getCross(tvec,e1)
	local v=getDot(r.n,qvec)*inv_det
	if v<0 or u+v>1 then return false end
	return getDot(e2,qvec)*inv_det
end

function closestInt(obj,r)
	local dist=false
	local id=0
	for i,p in pairs(obj.con) do
		local d=rayTriInt({a=obj.ver[p.a],b=obj.ver[p.b],c=obj.ver[p.c]},r)
		if d and d>0 then
			if dist then	if d<dist then id=i dist=d	end
			else id=i dist=d end
		end
	end
	return dist,id
end

compObj={
{row=0,s=10.5,tex=true,vlen=100,vtlen=342,clen=196},
{row=17,s=10.5,tex=false,vlen=44,vtlen=0,clen=51},
}
function unpackObj()
	for j,k in pairs(compObj) do
		local id=k.row*240
		local b=0
		if j==1 then b=objMap end
		if j==2 then b=objMapC end
		if j>2 then
			table.insert(obj,{ver={},con={},uvs={},ttp={}})
			b=obj[j-2]
		end
		
		for i=1,k.vlen do
			local temp={x=0,y=0,z=0}
			temp.x=((peek(0x8000+id)<<8)+peek(0x8001+id)-32768)/32767*k.s
			temp.y=((peek(0x8002+id)<<8)+peek(0x8003+id)-32768)/32767*k.s
			temp.z=((peek(0x8004+id)<<8)+peek(0x8005+id)-32768)/32767*k.s
			table.insert(b.ver,temp)	id=id+6
		end
		for i=1,k.clen do
			local temp={a=0,b=0,c=0}
			temp.a=(peek(0x8000+id)<<8)+peek(0x8001+id)
			temp.b=(peek(0x8002+id)<<8)+peek(0x8003+id)
			temp.c=(peek(0x8004+id)<<8)+peek(0x8005+id)
			table.insert(b.con,temp) id=id+6
		end
		if k.tex==true then
			for i=1,k.vtlen do
				local temp={u=0,v=0}
				temp.u=(peek(0x8000+id))
				temp.v=(peek(0x8001+id))
				table.insert(b.uvs,temp)	id=id+2
			end
			for i=1,k.clen do
				local temp={a=0,b=0,c=0}
				temp.a=(peek(0x8000+id)<<8)+peek(0x8001+id)
				temp.b=(peek(0x8002+id)<<8)+peek(0x8003+id)
				temp.c=(peek(0x8004+id)<<8)+peek(0x8005+id)
				table.insert(b.ttp,temp) id=id+6
			end
		end
	end
end

function BOOT()
	fov=90
	
	objMap={ver={},con={},uvs={},ttp={}}
	objMapC={ver={},con={}}
	obj={}
	
	plr={
		pos={x=-3,y=-3,z=0},
		rot={x=0,y=0,z=45},
		vel={x=0,y=0,z=0},
		bbw=0.6,h=1.8,ac=0.03,of=false
	}
	cam={
		pos={x=0,y=-2,z=0},
		rot={x=0,y=0,z=0}
	}
	scene={
		ver={},
		con={},
		uvs={},
		ttp={},
		pol={}
	}
	cplanes={
		{p={x=0,y=0.2,z=0},n={x=0,y=1,z=0}},
		{p={x=0,y=32,z=0},n={x=0,y=-1,z=0}},
		{p={x=0,y=0,z=0},n={x=1,y=fov/90,z=0}},
		{p={x=0,y=0,z=0},n={x=-1,y=fov/90,z=0}},
		{p={x=0,y=0,z=0},n={x=0,y=fov/158.8,z=-1}},
		{p={x=0,y=0,z=0},n={x=0,y=fov/158.8,z=1}}
	}
	portal={
		blue={
			pos={x=0,y=0,z=-2},
			rot={x=0,y=0,z=0},
			open=false,col=false,sa=0
		},
		orange={
			pos={x=0,y=0,z=-2},
			rot={x=0,y=0,z=0},
			open=false,col=false,sa=0
		},
		h=3,w=1.6
	}
	
	unpackObj()
end

function floorCollide()
	plr.of=false
	if not keyp(48) then
		for i=1,#objMapC.con do
			local p={a=objMapC.ver[objMapC.con[i].a],b=objMapC.ver[objMapC.con[i].b],c=objMapC.ver[objMapC.con[i].c]}
			if getDot(normalize(getNormal(p.a,p.b,p.c)),{x=0,y=0,z=-1})>0.5 then
				local dist=math.min(
					rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+plr.h*0.15},n={x=0,y=0,z=-1}}) or 1e+8,
					rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+plr.h*0.15},n={x=0,y=0,z=-1}}) or 1e+8,
					rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+plr.h*0.15},n={x=0,y=0,z=-1}}) or 1e+8,
					rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+plr.h*0.15},n={x=0,y=0,z=-1}}) or 1e+8)
				if dist>0 and dist<=plr.h*0.15 then
					plr.vel.z=0
					plr.pos.z=plr.pos.z+(plr.h*0.15-dist-0.01)
					plr.of=true
				elseif dist>plr.h*0.15 and dist<=plr.h*0.3 then
					--plr.vel.z=0
					--plr.pos.z=plr.pos.z+(plr.h/7.2-dist)
					plr.of=true
				end
			end
		end
	end
end

function wallCollide()
	for i=1,#objMapC.con do
		local p={a=objMapC.ver[objMapC.con[i].a],b=objMapC.ver[objMapC.con[i].b],c=objMapC.ver[objMapC.con[i].c]}
		local pn=normalize(getNormal(p.a,p.b,p.c))
		if getDot(pn,{x=0,y=0,z=-1})<=0.5 and getDot(pn,plr.vel)>0 then
			local dist=math.min(
				rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+0.25},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+0.25},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+0.25},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+0.25},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+plr.h},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y+plr.bbw/2,z=plr.pos.z+plr.h},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x-plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+plr.h},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8,
				rayTriInt(p,{p={x=plr.pos.x+plr.bbw/2,y=plr.pos.y-plr.bbw/2,z=plr.pos.z+plr.h},n={x=plr.vel.x,y=plr.vel.y,z=plr.vel.z}}) or 1e+8)
			if dist>=0 and dist<1 then
				plr.vel=getCross(pn,getCross(plr.vel,pn))
			end
		end
	end
end

function portalPlace(second)
	local prt=second and portal.orange or portal.blue
	local prt2=second and portal.blue or portal.orange
	local dist,pid=closestInt(objMap,{p={x=plr.pos.x,y=plr.pos.y,z=plr.pos.z+plr.h*0.9},n=rotatePoint({x=0,y=1,z=0},plr.rot)})
	if pid==0 then return end
	local pol=getTri(objMap,pid)
	if getLen(subP(pol.a,pol.c))<getLen(subP(pol.b,pol.c)) and getLen(subP(pol.a,pol.b))<getLen(subP(pol.b,pol.c)) then	if getLen(subP(lerp(pol.b,pol.c,0.5),prt2.pos))<portal.w then return end	end
	if getLen(subP(pol.b,pol.a))<getLen(subP(pol.c,pol.a)) and getLen(subP(pol.b,pol.c))<getLen(subP(pol.c,pol.a)) then	if getLen(subP(lerp(pol.a,pol.c,0.5),prt2.pos))<portal.w then return end	end
	if getLen(subP(pol.c,pol.b))<getLen(subP(pol.a,pol.b)) and getLen(subP(pol.c,pol.a))<getLen(subP(pol.a,pol.b)) then	if getLen(subP(lerp(pol.a,pol.b,0.5),prt2.pos))<portal.w then return end	end
	local tex={u=(objMap.uvs[objMap.ttp[pid].a].u+objMap.uvs[objMap.ttp[pid].b].u+objMap.uvs[objMap.ttp[pid].c].u)//3,v=(objMap.uvs[objMap.ttp[pid].a].v+objMap.uvs[objMap.ttp[pid].b].v+objMap.uvs[objMap.ttp[pid].c].v)//3}
	if not (tex.u>=0 and tex.u<64 and tex.v>=64 and tex.v<128) then return end
	local pn=normalize(getNormal(pol.a,pol.b,pol.c))
	if pn.x==-1 then prt.rot={x=0,y=0,z=90}
	elseif pn.x==1 then prt.rot={x=0,y=0,z=-90}
	elseif pn.y==-1 then prt.rot={x=0,y=0,z=0}
	elseif pn.y==1 then prt.rot={x=0,y=0,z=180}
	elseif pn.z==-1 then	prt.rot={x=-90,y=0,z=(plr.rot.z+225)//90*90}
	elseif pn.z==1 then	prt.rot={x=90,y=0,z=(plr.rot.z+225)//90*90}	end
	if getLen(subP(pol.a,pol.c))<getLen(subP(pol.b,pol.c)) and getLen(subP(pol.a,pol.b))<getLen(subP(pol.b,pol.c)) then
		prt.pos=addP(lerp(pol.b,pol.c,0.5),mulP(rotatePoint({x=0,y=1,z=0},prt.rot),0.01))
	end
	if getLen(subP(pol.b,pol.a))<getLen(subP(pol.c,pol.a)) and getLen(subP(pol.b,pol.c))<getLen(subP(pol.c,pol.a)) then
		prt.pos=addP(lerp(pol.a,pol.c,0.5),mulP(rotatePoint({x=0,y=1,z=0},prt.rot),0.01))
	end
	if getLen(subP(pol.c,pol.b))<getLen(subP(pol.a,pol.b)) and getLen(subP(pol.c,pol.a))<getLen(subP(pol.a,pol.b)) then
		prt.pos=addP(lerp(pol.a,pol.b,0.5),mulP(rotatePoint({x=0,y=1,z=0},prt.rot),0.01))
	end
	prt.open=true
	prt.sa=0
end

function portalPhys()
	for h=1,2 do
		local prt=h==1 and portal.blue or portal.orange
		local prt2=h==2 and portal.blue or portal.orange
		prt.sa=prt.sa+(1-prt.sa)*0.25
		if portal.blue.open and portal.orange.open then
			local cp=0
			for i=0,11 do
				if getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=0,y=0.09,z=0},prt.rot))),rotatePoint({x=0,y=1,z=0},prt.rot))<=0
				and getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot))),rotatePoint({x=-1,y=0,z=0},prt.rot))<=0
				and getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot))),rotatePoint({x=1,y=0,z=0},prt.rot))<=0
				and getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=0,y=0,z=-portal.h/2},prt.rot))),rotatePoint({x=0,y=0,z=-1},prt.rot))<=0
				and getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=0,y=0,z=portal.h/2},prt.rot))),rotatePoint({x=0,y=0,z=1},prt.rot))<=0
				and getDot(subP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or (i//4==1 and 0.15 or 1))},addP(prt.pos,rotatePoint({x=0,y=-plr.bbw,z=0},prt.rot))),rotatePoint({x=0,y=-1,z=0},prt.rot))<=0 then
					cp=cp+1
				end
			end
			if cp>=4 then prt.col=true else prt.col=false end
		end
		if prt.col then
			for i=0,7 do
				local p=addP({x=plr.pos.x+plr.bbw/2*(i%2==0 and -1 or 1),y=plr.pos.y+plr.bbw/2*(i//2%2==0 and -1 or 1),z=plr.pos.z+plr.h*(i//4==0 and 0 or 1)},plr.vel)
				if (getDot(rotatePoint({x=-1,y=0,z=0},prt.rot),plr.vel)>0 and getDot(subP(p,addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot))),rotatePoint({x=1,y=0,z=0},prt.rot))<0)
				or (getDot(rotatePoint({x=1,y=0,z=0},prt.rot),plr.vel)>0 and getDot(subP(p,addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot))),rotatePoint({x=-1,y=0,z=0},prt.rot))<0) then
					plr.vel=getCross(rotatePoint({x=-1,y=0,z=0},prt.rot),getCross(plr.vel,rotatePoint({x=-1,y=0,z=0},prt.rot)))
				end
				if (getDot(rotatePoint({x=0,y=0,z=1},prt.rot),plr.vel)>0 and getDot(subP(p,addP(prt.pos,mulP(rotatePoint({x=0,y=0,z=1},prt.rot),portal.h/2))),rotatePoint({x=0,y=0,z=-1},prt.rot))<0) then
					plr.vel=getCross(rotatePoint({x=0,y=0,z=1},prt.rot),getCross(plr.vel,rotatePoint({x=0,y=0,z=1},prt.rot)))
				end
			end
			if prt.rot.x==0 and plr.vel.z<0 then
				if plr.pos.z<=prt.pos.z-portal.h/2 then
					plr.vel.z=0.0
					plr.pos.z=prt.pos.z-portal.h/2
					plr.of=true
				end
			end
			if getDot(subP(plr.pos,prt.pos),rotatePoint({x=0,y=1,z=0},prt.rot))<0 then
				local temp=subP(prt2.rot,prt.rot) temp.z=temp.z+180
				local ofs=subP(plr.pos,prt.pos)
				ofs=rotatePoint(ofs,temp)
				plr.pos=addP(prt2.pos,ofs)
				plr.vel=rotatePoint(plr.vel,temp)
				plr.pos=addP(plr.pos,plr.vel)
				plr.rot=addP(plr.rot,{x=0,y=0,z=temp.z})
			end
		end
	end
end

function playerPhys()
	if key(23) then plr.vel.x=plr.vel.x+sin(plr.rot.z)*plr.ac*(plr.of and 1 or 0.02)     plr.vel.y=plr.vel.y+cos(plr.rot.z)*plr.ac*(plr.of and 1 or 0.02) end
	if key(19) then plr.vel.x=plr.vel.x+sin(plr.rot.z+180)*plr.ac*(plr.of and 1 or 0.02) plr.vel.y=plr.vel.y+cos(plr.rot.z+180)*plr.ac*(plr.of and 1 or 0.02) end
	if key(1)  then plr.vel.x=plr.vel.x+sin(plr.rot.z-90)*plr.ac*(plr.of and 1 or 0.02)  plr.vel.y=plr.vel.y+cos(plr.rot.z-90)*plr.ac*(plr.of and 1 or 0.02) end
	if key(4)  then plr.vel.x=plr.vel.x+sin(plr.rot.z+90)*plr.ac*(plr.of and 1 or 0.02)  plr.vel.y=plr.vel.y+cos(plr.rot.z+90)*plr.ac*(plr.of and 1 or 0.02) end
	if keyp(48) and plr.of then plr.vel.z=0.1 end
	plr.vel.x=plr.vel.x*(plr.of and 0.8 or 0.99)	plr.vel.y=plr.vel.y*(plr.of and 0.8 or 0.99)
	
	plr.vel.z=plr.vel.z-0.005
	portalPhys()
	if not (portal.blue.col or portal.orange.col) then
		wallCollide()
		floorCollide()
	end
	
	plr.pos=addP(plr.pos,plr.vel)
	cam.pos={x=plr.pos.x,y=plr.pos.y,z=plr.pos.z+plr.h*0.9+(plr.of and sin(t*16)*getLen(plr.vel)*0.5 or 0)}
	--cam.pos={x=plr.pos.x-sin(plr.rot.z)*cos(plr.rot.x)*plr.h*2,y=plr.pos.y-cos(plr.rot.z)*cos(plr.rot.x)*plr.h*2,z=plr.pos.z+plr.h/2+sin(plr.rot.x)*plr.h*2}
	cam.rot={x=plr.rot.x,y=plr.rot.y+getDot(rotatePoint({x=1,y=0,z=0},{x=0,y=0,z=plr.rot.z}),plr.vel)*16,z=plr.rot.z}
end

function sceneClip()
	for j,pl in pairs(cplanes) do
		for k=#scene.pol,1,-1 do
			local v={scene.pol[k].a,scene.pol[k].b,scene.pol[k].c}
			local d={getDot(subP(v[1],pl.p),pl.n),
			         getDot(subP(v[2],pl.p),pl.n),
			         getDot(subP(v[3],pl.p),pl.n)}
			local out={}
			if d[1]<0 and d[2]<0 and d[3]<0 then
				table.remove(scene.pol,k)
			elseif d[1]<0 or d[2]<0 or d[3]<0 then
				for i=1,3 do
					if d[i]>=0 and d[i%3+1]>=0 then
						table.insert(out,v[i])
					end
					if d[i]>=0 and d[i%3+1]<0 then
						table.insert(out,v[i])
						table.insert(out,lerp(v[i],v[i%3+1],d[i]/(d[i]-d[i%3+1])))
					end
					if d[i]<0 and d[i%3+1]>=0 then
						table.insert(out,lerp(v[i],v[i%3+1],d[i]/(d[i]-d[i%3+1])))
					end
				end
				scene.pol[k].a=out[1]
				scene.pol[k].b=out[2]
				scene.pol[k].c=out[3]
				if #out==4 then table.insert(scene.pol,{a=out[1],b=out[3],c=out[4]}) end
			end
		end
	end
end

function sceneCompose()
	scene.ver={} scene.con={} scene.uvs={} scene.ttp={} scene.pol={}
	for i,p in pairs(objMap.ver) do	table.insert(scene.ver,{x=p.x,y=p.y,z=p.z})	end
	for i,p in pairs(objMap.con) do	table.insert(scene.con,{a=p.a,b=p.b,c=p.c})	end
	for i,p in pairs(objMap.uvs) do	table.insert(scene.uvs,{u=p.u,v=p.v})	end
	for i,p in pairs(objMap.ttp) do	table.insert(scene.ttp,{a=p.a,b=p.b,c=p.c})	end
	
	for h=1,2 do
		local prt=h==1 and portal.blue or portal.orange
		local pb=transformCam(prt.pos)
		local ps={
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2*prt.sa},prt.rot))
		}
		table.insert(scene.ver,ps[1])	table.insert(scene.ver,ps[2])	table.insert(scene.ver,ps[3])	table.insert(scene.ver,ps[4])
		table.insert(scene.con,{a=#scene.ver-3,b=#scene.ver-2,c=#scene.ver-1}) table.insert(scene.con,{a=#scene.ver-3,b=#scene.ver-1,c=#scene.ver})
		table.insert(scene.uvs,{u=32+((portal.blue.open and portal.orange.open) and 64 or 0)+(h==1 and 0 or 32),v=0})
		table.insert(scene.uvs,{u=0+((portal.blue.open and portal.orange.open) and 64 or 0)+(h==1 and 0 or 32),v=0})
		table.insert(scene.uvs,{u=0+((portal.blue.open and portal.orange.open) and 64 or 0)+(h==1 and 0 or 32),v=64})
		table.insert(scene.uvs,{u=32+((portal.blue.open and portal.orange.open) and 64 or 0)+(h==1 and 0 or 32),v=64})
		table.insert(scene.ttp,{a=#scene.uvs-3,b=#scene.uvs-2,c=#scene.uvs-1}) table.insert(scene.ttp,{a=#scene.uvs-3,b=#scene.uvs-1,c=#scene.uvs})
	end
	
	for i=1,#scene.ver do
		scene.ver[i]=transformCam(scene.ver[i])
	end
	for i,con in pairs(scene.con) do
		local p={a=scene.ver[con.a],b=scene.ver[con.b],c=scene.ver[con.c]}
		local pt={a={u=0,v=0},b={u=0,v=0},c={u=0,v=0}}
		if scene.ttp[i] then pt={a=scene.uvs[scene.ttp[i].a],b=scene.uvs[scene.ttp[i].b],c=scene.uvs[scene.ttp[i].c]} end
		if getDot(getNormal(p.a,p.b,p.c),normalize(p.a))>0 then
			table.insert(scene.pol,{a={x=p.a.x,y=p.a.y,z=p.a.z,u=pt.a.u,v=pt.a.v},b={x=p.b.x,y=p.b.y,z=p.b.z,u=pt.b.u,v=pt.b.v},c={x=p.c.x,y=p.c.y,z=p.c.z,u=pt.c.u,v=pt.c.v}})
		end
	end
	sceneClip()
end

function scenePortal(second)
	local prt=second and portal.orange or portal.blue
	local prt2=second and portal.blue or portal.orange
	scene.ver={} scene.con={} scene.uvs={} scene.ttp={} scene.pol={}
	for i,p in pairs(objMap.ver) do	table.insert(scene.ver,{x=p.x,y=p.y,z=p.z})	end
	for i,p in pairs(objMap.con) do	table.insert(scene.con,{a=p.a,b=p.b,c=p.c})	end
	for i,p in pairs(objMap.uvs) do	table.insert(scene.uvs,{u=p.u,v=p.v})	end
	for i,p in pairs(objMap.ttp) do	table.insert(scene.ttp,{a=p.a,b=p.b,c=p.c})	end
	
	for h=1,2 do
		local prt=h==1 and portal.blue or portal.orange
		local pb=transformCam(prt.pos)
		local ps={
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2*prt.sa},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2*prt.sa,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2*prt.sa},prt.rot))
		}
		table.insert(scene.ver,ps[1])	table.insert(scene.ver,ps[2])	table.insert(scene.ver,ps[3])	table.insert(scene.ver,ps[4])
		table.insert(scene.con,{a=#scene.ver-3,b=#scene.ver-2,c=#scene.ver-1}) table.insert(scene.con,{a=#scene.ver-3,b=#scene.ver-1,c=#scene.ver})
		table.insert(scene.uvs,{u=32+(h==1 and 0 or 32),v=0})
		table.insert(scene.uvs,{u=0+(h==1 and 0 or 32),v=0})
		table.insert(scene.uvs,{u=0+(h==1 and 0 or 32),v=64})
		table.insert(scene.uvs,{u=32+(h==1 and 0 or 32),v=64})
		table.insert(scene.ttp,{a=#scene.uvs-3,b=#scene.uvs-2,c=#scene.uvs-1}) table.insert(scene.ttp,{a=#scene.uvs-3,b=#scene.uvs-1,c=#scene.uvs})
	end
	
	for i=1,#scene.ver do
		scene.ver[i]=subP(scene.ver[i],prt2.pos)
		scene.ver[i]=rotatePoint(scene.ver[i],addP(subP(prt.rot,prt2.rot),{x=0,y=0,z=180}))
		scene.ver[i]=addP(scene.ver[i],prt.pos)
		scene.ver[i]=transformCam(scene.ver[i])
	end
	for i,con in pairs(scene.con) do
		local p={a=scene.ver[con.a],b=scene.ver[con.b],c=scene.ver[con.c]}
		local pt={a={u=0,v=0},b={u=0,v=0},c={u=0,v=0}}
		if scene.ttp[i] then pt={a=scene.uvs[scene.ttp[i].a],b=scene.uvs[scene.ttp[i].b],c=scene.uvs[scene.ttp[i].c]} end
		if getDot(getNormal(p.a,p.b,p.c),normalize(p.a))>0 then
			table.insert(scene.pol,{a={x=p.a.x,y=p.a.y,z=p.a.z,u=pt.a.u,v=pt.a.v},b={x=p.b.x,y=p.b.y,z=p.b.z,u=pt.b.u,v=pt.b.v},c={x=p.c.x,y=p.c.y,z=p.c.z,u=pt.c.u,v=pt.c.v}})
		end
	end
	local pp={
		addP(addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2},prt.rot)),
		addP(addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2},prt.rot)),
		addP(addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2},prt.rot)),
		addP(addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2},prt.rot))
	}
	for i=1,#pp do pp[i]=transformCam(pp[i]) end
	
	cplanes[1].p=transformCam(prt.pos)
	cplanes[1].n=getNormal(pp[1],pp[3],pp[2])
	cplanes[3].n=getNormal(pp[1],pp[3],{x=0,y=0,z=0})
	cplanes[4].n=getNormal(pp[4],pp[2],{x=0,y=0,z=0})
	cplanes[5].n=getNormal(pp[2],pp[1],{x=0,y=0,z=0})
	cplanes[6].n=getNormal(pp[3],pp[4],{x=0,y=0,z=0})
	sceneClip()
	
	cplanes[1]={p={x=0,y=0.2,z=0},n={x=0,y=1,z=0}}
	cplanes[2]={p={x=0,y=32,z=0},n={x=0,y=-1,z=0}}
	cplanes[3]={p={x=0,y=0,z=0},n={x=1,y=fov/90,z=0}}
	cplanes[4]={p={x=0,y=0,z=0},n={x=-1,y=fov/90,z=0}}
	cplanes[5]={p={x=0,y=0,z=0},n={x=0,y=fov/158.8,z=-1}}
	cplanes[6]={p={x=0,y=0,z=0},n={x=0,y=fov/158.8,z=1}}

	sceneClip()
end

function sceneRender()
	--table.sort(scene.pol,function(a,b) return a.a.y+a.b.y+a.c.y>b.a.y+b.b.y+b.c.y end)
	for i,p in pairs(scene.pol) do
		ttri(120+p.a.x/p.a.y*10800/fov,68-p.a.z/p.a.y*10800/fov,120+p.b.x/p.b.y*10800/fov,68-p.b.z/p.b.y*10800/fov,120+p.c.x/p.c.y*10800/fov,68-p.c.z/p.c.y*10800/fov,p.a.u,p.a.v,p.b.u,p.b.v,p.c.u,p.c.v,0,5,p.a.y,p.b.y,p.c.y)
		--trib(120+p.a.x/p.a.y*10800/fov,68-p.a.z/p.a.y*10800/fov,120+p.b.x/p.b.y*10800/fov,68-p.b.z/p.b.y*10800/fov,120+p.c.x/p.c.y*10800/fov,68-p.c.z/p.c.y*10800/fov,0)
	end
	--[[for h=1,2 do
		local prt=h==1 and portal.blue or portal.orange
		local pb=transformCam(prt.pos)
		local pn=transformCam(addP(prt.pos,rotatePoint({x=0,y=1,z=0},prt.rot)))
		local pt=transformCam(addP(prt.pos,rotatePoint({x=0,y=0,z=1},prt.rot)))
		local ps={
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=portal.h/2},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2},prt.rot)),
			addP(addP(prt.pos,rotatePoint({x=-portal.w/2,y=0,z=0},prt.rot)),rotatePoint({x=0,y=0,z=-portal.h/2},prt.rot))
		}
		for i=1,#ps do ps[i]=transformCam(ps[i]) end
		if pb.y>0 and prt.open then
			for i=1,#ps do line(120+ps[i].x/ps[i].y*10800/fov,68-ps[i].z/ps[i].y*10800/fov,120+ps[i%4+1].x/ps[i%4+1].y*10800/fov,68-ps[i%4+1].z/ps[i%4+1].y*10800/fov,h==1 and 10 or 4) end
			circ(120+pb.x/pb.y*10800/fov,68-pb.z/pb.y*10800/fov,16//pb.y,h==1 and 10 or 4)
			line(120+pb.x/pb.y*10800/fov,68-pb.z/pb.y*10800/fov,120+pn.x/pn.y*10800/fov,68-pn.z/pn.y*10800/fov,6)
			line(120+pb.x/pb.y*10800/fov,68-pb.z/pb.y*10800/fov,120+pt.x/pt.y*10800/fov,68-pt.z/pt.y*10800/fov,9)
			print("x: "..prt.rot.x.."\ny: "..prt.rot.y.."\nz: "..prt.rot.z,120+pb.x/pb.y*10800/fov+8,68-pb.z/pb.y*10800/fov-8,12,true,1,true)
		end
	end]]
end

tp=0 fps=0 tot=0 ts=0
function fpsCounter(ms)
	tot=tot+(time()-tp) ts=ts+1
	--tp=time()
	if tot>=ms then fps=math.floor(ts*1000/tot+0.5) tot=0 ts=0 end
	print(fps.." fps",2,2,12,true,1,true)
end

function OVR()
	sceneCompose()
	sceneRender()
	
	rect(119,65,3,7,15)
	rect(117,67,7,3,15)
	rect(120,66,1,5,12)
	rect(118,68,5,1,12)
	fpsCounter(500)
end

poke(0x7FC3F,1,1)
function TIC()
	tp=time()
	pml,pmr=ml or false,mr or false
	mx,my,ml,mw,mr=mouse()
	plr.rot.z=plr.rot.z+mx*0.15
	plr.rot.x=plr.rot.x+my*0.15
	if plr.rot.x<-90 then plr.rot.x=-90 end
	if plr.rot.x>90 then plr.rot.x=90 end
	playerPhys()
	if ml and not pml then portalPlace(false) end
	if mr and not pmr then portalPlace(true) end
	
	cls()
	scenePortal(false)
	sceneRender()
	scenePortal(true)
	sceneRender()
	t=t+1
end

-- <TILES>
-- 000:55555555555555555555555555555555555555555555555955555599555555a9
-- 001:5555599955599999559999885999888899988888998888889888888888888888
-- 002:9995555599999555889999558888999588888999888888998888888988888888
-- 003:55555555555555555555555555555555555555559555555599555555a9555555
-- 004:5555555555555555555555555555555555555555555555525555552255555532
-- 005:5555522255522222552222115222111122211111221111112111111111111111
-- 006:2225555522222555112222551111322511111222111111321111111211111111
-- 007:5555555555555555555555555555555555555555255555552255555532555555
-- 008:55555555555555555555555555555555555555555555555955555599555555a9
-- 009:5555599955599999559999005999000099900000990000009000000000000000
-- 010:9995555599999555009999550000999500000999000000990000000900000000
-- 011:55555555555555555555555555555555555555559555555599555555a9555555
-- 012:5555555555555555555555555555555555555555555555525555552255555532
-- 013:5555522255522222552222005222000022200000220000002000000000000000
-- 014:2225555522222555002222550000322500000222000000320000000200000000
-- 015:5555555555555555555555555555555555555555255555552255555532555555
-- 016:55555998555559a8555599885555a988555998885559a888555a988855a98888
-- 017:8888888888888888888888888888888888888888888888888888888888888888
-- 018:8888888888888888888888888888888888888888888888888888888888888888
-- 019:8995555589a555558899555588a95555888995558889a555888a95558888a955
-- 020:5555522155555231555523115555321155532111555231115553211155321111
-- 021:1111111111111111111111111111111111111111111111111111111111111111
-- 022:1111111111111111111111111111111111111111111111111111111111111111
-- 023:1225555512355555112255551132555511132555111235551113255511113255
-- 024:55555990555559a0555599005555a900555990005559a000555a900055a90000
-- 027:0995555509a555550099555500a95555000995550009a555000a95550000a955
-- 028:5555522055555230555523005555320055532000555230005553200055320000
-- 031:0225555502355555002255550032555500032555000235550003255500003255
-- 032:559a888855a98888559a88885aa888885a9888885aa888885a9888885aa88888
-- 033:8888888888888888888888888888888888888888888888888888888888888888
-- 034:8888888888888888888888888888888888888888888888888888888888888888
-- 035:88889a558888a95588889a5588888aa588888a9588888aa588888a9588888aa5
-- 036:5523111155321111552311115331111153211111523111115321111153311111
-- 037:1111111111111111111111111111111111111111111111111111111111111111
-- 038:1111111111111111111111111111111111111111111111111111111111111111
-- 039:1111235511113255111123551111133511111325111112351111132511111335
-- 040:559a000055a90000559a00005aa000005a9000005aa000005a9000005aa00000
-- 043:00009a550000a95500009a5500000aa500000a9500000aa500000a9500000aa5
-- 044:5523000055320000552300005330000053200000523000005320000053300000
-- 047:0000235500003255000023550000033500000325000002350000032500000335
-- 048:9a888888aa888888aa888888aa888888aa888888aa888888aa888888aa888888
-- 049:8888888888888888888888888888888888888888888888888888888888888888
-- 050:8888888888888888888888888888888888888888888888888888888888888888
-- 051:8888889a888888aa888888aa888888aa888888aa888888aa888888aa888888aa
-- 052:2311111133111111331111113311111123111111331111113311111133111111
-- 053:1111111111111111111111111111111111111111111111111111111111111111
-- 054:1111111111111111111111111111111111111111111111111111111111111111
-- 055:1111112311111133111111231111113311111133111111331111113311111133
-- 056:9a000000aa000000aa000000aa000000aa000000aa000000aa000000aa000000
-- 059:0000009a000000aa000000aa000000aa000000aa000000aa000000aa000000aa
-- 060:2300000033000000330000003300000023000000330000003300000033000000
-- 063:0000002300000033000000230000003300000033000000330000003300000033
-- 064:aa988888aa988888aa998888aa999888aa999988aa999999aa999999ba999999
-- 065:8888888888888888888888888888888888888888888888889888888899998888
-- 066:8888888888888888888888888888888888888888888888888888888988889999
-- 067:888889aa888889aa888899aa888999aa889999aa999999aa999999aa999999ba
-- 068:3321111133211111332211114322211133222211332222223322222243222222
-- 069:1111111111111111111111111111111111111111111111112111111122221111
-- 070:1111111111111111111111111111111111111111111111111111111211112222
-- 071:1111123311111233111122331112223311222233222222432222223322222243
-- 072:aa000000aa000000aa000000aa000000aa000000aa000000aa000000ba000000
-- 075:000000aa000000aa000000aa000000aa000000aa000000aa000000aa000000ba
-- 076:3300000033000000330000004300000033000000330000003300000043000000
-- 079:0000003300000033000000330000003300000033000000430000003300000043
-- 080:5aa999995ab999995aa999995ab999995aa9999955ba999955ab999955ba9999
-- 081:9999999999999999999999999999999999999999999999999999999999999999
-- 082:9999999999999999999999999999999999999999999999999999999999999999
-- 083:99999aa599999ab599999aa599999ab599999aa59999ba559999ab559999ba55
-- 084:5332222253422222543222225342222253322222554322225534222255432222
-- 085:2222222222222222222222222222222222222222222222222222222222222222
-- 086:2222222222222222222222222222222222222222222222222222222222222222
-- 087:2222233522222345222224352222234522222335222243552222345522224355
-- 088:5aa000005ab000005aa000005ab000005aa0000055ba000055ab000055ba0000
-- 091:00000aa500000ab500000aa500000ab500000aa50000ba550000ab550000ba55
-- 092:5330000053400000543000005340000053300000554300005534000055430000
-- 095:0000033500000345000004350000034500000335000043550000345500004355
-- 096:55ab9999555ab999555ba999555bb9995555ab995555bb9955555ba955555bb9
-- 097:9999999999999999999999999999999999999999999999999999999999999999
-- 098:9999999999999999999999999999999999999999999999999999999999999999
-- 099:9999ab55999ab555999ba555999bb55599ab555599bb55559ba555559bb55555
-- 100:5534222255534222555432225553422255553422555543225555543255555442
-- 101:2222222222222222222222222222222222222222222222222222222222222222
-- 102:2222222222222222222222222222222222222222222222222222222222222222
-- 103:2222345522234555222435552223455522345555224455552435555524455555
-- 104:55ab0000555ab000555ba000555bb0005555ab005555bb0055555ba055555bb0
-- 107:0000ab55000ab555000ba555000bb55500ab555500bb55550ba555550bb55555
-- 108:5534000055534000555430005553400055553400555543005555543055555440
-- 111:0000345500034555000435550003455500345555004455550435555504455555
-- 112:555555ab555555bb5555555b5555555555555555555555555555555555555555
-- 113:99999999b9999999bb999999bbb999995bbb999955bbbb99555bbbbb55555bbb
-- 114:999999999999999b999999bb99999bbb9999bbb599bbbb55bbbbb555bbb55555
-- 115:ab555555bb555555b55555555555555555555555555555555555555555555555
-- 116:5555553455555544555555545555555555555555555555555555555555555555
-- 117:2222222242222222442222224442222254442222554444225554444455555444
-- 118:2222222222222224222222342222244422223445224444554444455544455555
-- 119:3455555544555555455555555555555555555555555555555555555555555555
-- 120:555555ab555555bb5555555b5555555555555555555555555555555555555555
-- 121:00000000b0000000bb000000bbb000005bbb000055bbbb00555bbbbb55555bbb
-- 122:000000000000000b000000bb00000bbb0000bbb500bbbb55bbbbb555bbb55555
-- 123:ab555555bb555555b55555555555555555555555555555555555555555555555
-- 124:5555553455555544555555545555555555555555555555555555555555555555
-- 125:0000000040000000440000004440000054440000554444005554444455555444
-- 126:0000000000000004000000340000044400003445004444554444455544455555
-- 127:3455555544555555455555555555555555555555555555555555555555555555
-- 128:ddddddddddddddddddccccccddccccccddccccccddccccccddccccccddcccccc
-- 129:ddddddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:ddddddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccc
-- 131:ddddddddddddddddcccccccccccccccccccccccdcccccccdcccccccdcccccccd
-- 132:ddddddddddddddddccccccccccccccccdcccccccdcccccccdcccccccdccccccc
-- 133:ddddddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:ddddddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:dddddddddddddddecccccceecccccceecccccceecccccceecccccceeccccccee
-- 136:eeeeeeeeeeeeeeeeeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 137:eeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffff
-- 138:eeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffff
-- 139:eeeeeeeeeeeeeeeefffffffffffffffffffffffefffffffefffffffefffffffe
-- 140:eeeeeeeeeeeeeeeeffffffffffffffffefffffffefffffffefffffffefffffff
-- 141:eeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffff
-- 142:eeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffff
-- 143:eeeeeeeeeeeeeeeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 144:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 145:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 146:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 147:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 148:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 149:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 150:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 151:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 152:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 153:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 154:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 155:fffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 156:efffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffff
-- 157:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 158:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 159:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 160:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 161:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 162:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 163:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 164:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 165:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 166:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 167:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 168:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 169:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 170:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 171:fffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 172:efffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffff
-- 173:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 174:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 175:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 176:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 177:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 178:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 179:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 180:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 181:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 182:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 183:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 184:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffeeee
-- 185:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeee
-- 186:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeee
-- 187:fffffffefffffffefffffffefffffffefffffffefffffffefffffffeeeeeeeee
-- 188:efffffffefffffffefffffffefffffffefffffffefffffffefffffffeeeeeeee
-- 189:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeee
-- 190:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeee
-- 191:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeeeeeffee
-- 192:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 193:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 194:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 195:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 196:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 197:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 198:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 199:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 200:eeffeeeeeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 201:eeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:eeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 203:eeeeeeeefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 204:eeeeeeeeefffffffefffffffefffffffefffffffefffffffefffffffefffffff
-- 205:eeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 206:eeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 207:eeeeffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 208:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 209:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 210:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 211:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 212:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 213:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 214:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 215:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 216:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 217:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 218:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 219:fffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 220:efffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffff
-- 221:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 223:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 224:ddccccccddccccccddccccccddccccccddccccccddccccccddccccccddcccccc
-- 225:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 226:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 227:cccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccd
-- 228:dcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdccccccc
-- 229:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 230:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 231:cccccceecccccceecccccceecccccceecccccceecccccceecccccceeccccccee
-- 232:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffff
-- 233:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 234:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 235:fffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 236:efffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffff
-- 237:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 238:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 239:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeffffffee
-- 240:ddccccccddccccccddccccccddccccccddccccccddccccccddeeeeeedeeeeeee
-- 241:cccccccccccccccccccccccccccccccccccccccccccccccceeeeeeeeeeeeeeee
-- 242:cccccccccccccccccccccccccccccccccccccccccccccccceeeeeeeeeeeeeeee
-- 243:cccccccdcccccccdcccccccdcccccccdcccccccccccccccceeeeeeeeeeeeeeee
-- 244:dcccccccdcccccccdcccccccdccccccccccccccccccccccceeeeeeeeeeeeeeee
-- 245:cccccccccccccccccccccccccccccccccccccccccccccccceeeeeeeeeeeeeeee
-- 246:cccccccccccccccccccccccccccccccccccccccccccccccceeeeeeeeeeeeeeee
-- 247:cccccceecccccceecccccceecccccceecccccceecccccceeeeeeeeeeeeeeeeee
-- 248:eeffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeeeeeeeeeeeeeee
-- 249:ffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 250:ffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 251:fffffffefffffffefffffffefffffffeffffffffffffffffeeeeeeeeeeeeeeee
-- 252:efffffffefffffffefffffffefffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 255:ffffffeeffffffeeffffffeeffffffeeffffffeeffffffeeeeeeeeeeeeeeeeee
-- </TILES>

-- <SPRITES>
-- 000:00000000000000000eee0eee0e0e0e0e0e0e0e0e0e0e0e0e0eee0eee00000000
-- 001:00000000000000000eee00c00e0e0cc00e0e00c00e0e00c00eee0ccc00000000
-- 002:00000000000000000eee0cc00e0e000c0e0e00c00e0e0c000eee0ccc00000000
-- 003:00000000000000000eee0cc00e0e000c0e0e00c00e0e000c0eee0cc000000000
-- 004:00000000000000000eee000c0e0e00cc0e0e0c0c0e0e0ccc0eee000c00000000
-- 005:00000000000000000eee0ccc0e0e0c000e0e0ccc0e0e000c0eee0cc000000000
-- 006:00000000000000000eee00cc0e0e0c000e0e0ccc0e0e0c0c0eee0ccc00000000
-- 007:00000000000000000eee0ccc0e0e000c0e0e00c00e0e0c000eee0c0000000000
-- 008:00000000000000000eee0ccc0e0e0c0c0e0e00c00e0e0c0c0eee0ccc00000000
-- 009:00000000000000000eee0ccc0e0e0c0c0e0e0ccc0e0e000c0eee0cc000000000
-- 010:00000000000000000eee00550e0e05050e0e05050e0e05550eee050500000000
-- 011:00000000000000000eee05550e0e05050e0e05500e0e05050eee055500000000
-- 012:00000000000000000eee00550e0e05000e0e05000e0e05000eee005500000000
-- 013:00000000000000000eee05500e0e05050e0e05050e0e05050eee055000000000
-- 014:00000000000000000eee05550e0e05000e0e05500e0e05000eee055500000000
-- 015:00000000000000000eee05550e0e05000e0e05500e0e05000eee050000000000
-- 016:000000000000000000c00eee0cc00e0e00c00e0e00c00e0e0ccc0eee00000000
-- 017:000000000000000000c000c00cc00cc000c000c000c000c00ccc0ccc00000000
-- 018:000000000000000000c00cc00cc0000c00c000c000c00c000ccc0ccc00000000
-- 019:000000000000000000c00cc00cc0000c00c000c000c0000c0ccc0cc000000000
-- 020:000000000000000000c0000c0cc000cc00c00c0c00c00ccc0ccc000c00000000
-- 021:000000000000000000c00ccc0cc00c0000c00ccc00c0000c0ccc0cc000000000
-- 022:000000000000000000c000cc0cc00c0000c00ccc00c00c0c0ccc0ccc00000000
-- 023:000000000000000000c00ccc0cc0000c00c000c000c00c000ccc0c0000000000
-- 024:000000000000000000c00ccc0cc00c0c00c000c000c00c0c0ccc0ccc00000000
-- 025:000000000000000000c00ccc0cc00c0c00c00ccc00c0000c0ccc0cc000000000
-- 026:000000000000000000c000550cc0050500c0050500c005550ccc050500000000
-- 027:000000000000000000c005550cc0050500c0055000c005050ccc055500000000
-- 028:000000000000000000c000550cc0050000c0050000c005000ccc005500000000
-- 029:000000000000000000c005500cc0050500c0050500c005050ccc055000000000
-- 030:000000000000000000c005550cc0050000c0055000c005000ccc055500000000
-- 031:000000000000000000c005550cc0050000c0055000c005000ccc050000000000
-- 032:00000000000000000cc00eee000c0e0e00c00e0e0c000e0e0ccc0eee00000000
-- 033:00000000000000000cc000c0000c0cc000c000c00c0000c00ccc0ccc00000000
-- 034:00000000000000000cc00cc0000c000c00c000c00c000c000ccc0ccc00000000
-- 035:00000000000000000cc00cc0000c000c00c000c00c00000c0ccc0cc000000000
-- 036:00000000000000000cc0000c000c00cc00c00c0c0c000ccc0ccc000c00000000
-- 037:00000000000000000cc00ccc000c0c0000c00ccc0c00000c0ccc0cc000000000
-- 038:00000000000000000cc000cc000c0c0000c00ccc0c000c0c0ccc0ccc00000000
-- 039:00000000000000000cc00ccc000c000c00c000c00c000c000ccc0c0000000000
-- 040:00000000000000000cc00ccc000c0c0c00c000c00c000c0c0ccc0ccc00000000
-- 041:00000000000000000cc00ccc000c0c0c00c00ccc0c00000c0ccc0cc000000000
-- 042:00000000000000000cc00055000c050500c005050c0005550ccc050500000000
-- 043:00000000000000000cc00555000c050500c005500c0005050ccc055500000000
-- 044:00000000000000000cc00055000c050000c005000c0005000ccc005500000000
-- 045:00000000000000000cc00550000c050500c005050c0005050ccc055000000000
-- 046:00000000000000000cc00555000c050000c005500c0005000ccc055500000000
-- 047:00000000000000000cc00555000c050000c005500c0005000ccc050000000000
-- 048:00000000000000000cc00eee000c0e0e00c00e0e000c0e0e0cc00eee00000000
-- 049:00000000000000000cc000c0000c0cc000c000c0000c00c00cc00ccc00000000
-- 050:00000000000000000cc00cc0000c000c00c000c0000c0c000cc00ccc00000000
-- 051:00000000000000000cc00cc0000c000c00c000c0000c000c0cc00cc000000000
-- 052:00000000000000000cc0000c000c00cc00c00c0c000c0ccc0cc0000c00000000
-- 053:00000000000000000cc00ccc000c0c0000c00ccc000c000c0cc00cc000000000
-- 054:00000000000000000cc000cc000c0c0000c00ccc000c0c0c0cc00ccc00000000
-- 055:00000000000000000cc00ccc000c000c00c000c0000c0c000cc00c0000000000
-- 056:00000000000000000cc00ccc000c0c0c00c000c0000c0c0c0cc00ccc00000000
-- 057:00000000000000000cc00ccc000c0c0c00c00ccc000c000c0cc00cc000000000
-- 058:00000000000000000cc00055000c050500c00505000c05550cc0050500000000
-- 059:00000000000000000cc00555000c050500c00550000c05050cc0055500000000
-- 060:00000000000000000cc00055000c050000c00500000c05000cc0005500000000
-- 061:00000000000000000cc00550000c050500c00505000c05050cc0055000000000
-- 062:00000000000000000cc00555000c050000c00550000c05000cc0055500000000
-- 063:00000000000000000cc00555000c050000c00550000c05000cc0050000000000
-- 064:00000000000000000c0c0eee0c0c0e0e00cc0e0e000c0e0e000c0eee00000000
-- 065:00000000000000000c0c00c00c0c0cc000cc00c0000c00c0000c0ccc00000000
-- 066:00000000000000000c0c0cc00c0c000c00cc00c0000c0c00000c0ccc00000000
-- 067:00000000000000000c0c0cc00c0c000c00cc00c0000c000c000c0cc000000000
-- 068:00000000000000000c0c000c0c0c00cc00cc0c0c000c0ccc000c000c00000000
-- 069:00000000000000000c0c0ccc0c0c0c0000cc0ccc000c000c000c0cc000000000
-- 070:00000000000000000c0c00cc0c0c0c0000cc0ccc000c0c0c000c0ccc00000000
-- 071:00000000000000000c0c0ccc0c0c000c00cc00c0000c0c00000c0c0000000000
-- 072:00000000000000000c0c0ccc0c0c0c0c00cc00c0000c0c0c000c0ccc00000000
-- 073:00000000000000000c0c0ccc0c0c0c0c00cc0ccc000c000c000c0cc000000000
-- 074:00000000000000000c0c00550c0c050500cc0505000c0555000c050500000000
-- 075:00000000000000000c0c05550c0c050500cc0550000c0505000c055500000000
-- 076:00000000000000000c0c00550c0c050000cc0500000c0500000c005500000000
-- 077:00000000000000000c0c05500c0c050500cc0505000c0505000c055000000000
-- 078:00000000000000000c0c05550c0c050000cc0550000c0500000c055500000000
-- 079:00000000000000000c0c05550c0c050000cc0550000c0500000c050000000000
-- 080:00000000000000000ccc0eee0c000e0e0ccc0e0e000c0e0e0cc00eee00000000
-- 081:00000000000000000ccc00c00c000cc00ccc00c0000c00c00cc00ccc00000000
-- 082:00000000000000000ccc0cc00c00000c0ccc00c0000c0c000cc00ccc00000000
-- 083:00000000000000000ccc0cc00c00000c0ccc00c0000c000c0cc00cc000000000
-- 084:00000000000000000ccc000c0c0000cc0ccc0c0c000c0ccc0cc0000c00000000
-- 085:00000000000000000ccc0ccc0c000c000ccc0ccc000c000c0cc00cc000000000
-- 086:00000000000000000ccc00cc0c000c000ccc0ccc000c0c0c0cc00ccc00000000
-- 087:00000000000000000ccc0ccc0c00000c0ccc00c0000c0c000cc00c0000000000
-- 088:00000000000000000ccc0ccc0c000c0c0ccc00c0000c0c0c0cc00ccc00000000
-- 089:00000000000000000ccc0ccc0c000c0c0ccc0ccc000c000c0cc00cc000000000
-- 090:00000000000000000ccc00550c0005050ccc0505000c05550cc0050500000000
-- 091:00000000000000000ccc05550c0005050ccc0550000c05050cc0055500000000
-- 092:00000000000000000ccc00550c0005000ccc0500000c05000cc0005500000000
-- 093:00000000000000000ccc05500c0005050ccc0505000c05050cc0055000000000
-- 094:00000000000000000ccc05550c0005000ccc0550000c05000cc0055500000000
-- 095:00000000000000000ccc05550c0005000ccc0550000c05000cc0050000000000
-- 096:000000000000000000cc0eee0c000e0e0ccc0e0e0c0c0e0e0ccc0eee00000000
-- 097:000000000000000000cc00c00c000cc00ccc00c00c0c00c00ccc0ccc00000000
-- 098:000000000000000000cc0cc00c00000c0ccc00c00c0c0c000ccc0ccc00000000
-- 099:000000000000000000cc0cc00c00000c0ccc00c00c0c000c0ccc0cc000000000
-- 100:000000000000000000cc000c0c0000cc0ccc0c0c0c0c0ccc0ccc000c00000000
-- 101:000000000000000000cc0ccc0c000c000ccc0ccc0c0c000c0ccc0cc000000000
-- 102:000000000000000000cc00cc0c000c000ccc0ccc0c0c0c0c0ccc0ccc00000000
-- 103:000000000000000000cc0ccc0c00000c0ccc00c00c0c0c000ccc0c0000000000
-- 104:000000000000000000cc0ccc0c000c0c0ccc00c00c0c0c0c0ccc0ccc00000000
-- 105:000000000000000000cc0ccc0c000c0c0ccc0ccc0c0c000c0ccc0cc000000000
-- 106:000000000000000000cc00550c0005050ccc05050c0c05550ccc050500000000
-- 107:000000000000000000cc05550c0005050ccc05500c0c05050ccc055500000000
-- 108:000000000000000000cc00550c0005000ccc05000c0c05000ccc005500000000
-- 109:000000000000000000cc05500c0005050ccc05050c0c05050ccc055000000000
-- 110:000000000000000000cc05550c0005000ccc05500c0c05000ccc055500000000
-- 111:000000000000000000cc05550c0005000ccc05500c0c05000ccc050000000000
-- 112:00000000000000000ccc0eee000c0e0e00c00e0e0c000e0e0c000eee00000000
-- 113:00000000000000000ccc00c0000c0cc000c000c00c0000c00c000ccc00000000
-- 114:00000000000000000ccc0cc0000c000c00c000c00c000c000c000ccc00000000
-- 115:00000000000000000ccc0cc0000c000c00c000c00c00000c0c000cc000000000
-- 116:00000000000000000ccc000c000c00cc00c00c0c0c000ccc0c00000c00000000
-- 117:00000000000000000ccc0ccc000c0c0000c00ccc0c00000c0c000cc000000000
-- 118:00000000000000000ccc00cc000c0c0000c00ccc0c000c0c0c000ccc00000000
-- 119:00000000000000000ccc0ccc000c000c00c000c00c000c000c000c0000000000
-- 120:00000000000000000ccc0ccc000c0c0c00c000c00c000c0c0c000ccc00000000
-- 121:00000000000000000ccc0ccc000c0c0c00c00ccc0c00000c0c000cc000000000
-- 122:00000000000000000ccc0055000c050500c005050c0005550c00050500000000
-- 123:00000000000000000ccc0555000c050500c005500c0005050c00055500000000
-- 124:00000000000000000ccc0055000c050000c005000c0005000c00005500000000
-- 125:00000000000000000ccc0550000c050500c005050c0005050c00055000000000
-- 126:00000000000000000ccc0555000c050000c005500c0005000c00055500000000
-- 127:00000000000000000ccc0555000c050000c005500c0005000c00050000000000
-- 128:00000000000000000ccc0eee0c0c0e0e00c00e0e0c0c0e0e0ccc0eee00000000
-- 129:00000000000000000ccc00c00c0c0cc000c000c00c0c00c00ccc0ccc00000000
-- 130:00000000000000000ccc0cc00c0c000c00c000c00c0c0c000ccc0ccc00000000
-- 131:00000000000000000ccc0cc00c0c000c00c000c00c0c000c0ccc0cc000000000
-- 132:00000000000000000ccc000c0c0c00cc00c00c0c0c0c0ccc0ccc000c00000000
-- 133:00000000000000000ccc0ccc0c0c0c0000c00ccc0c0c000c0ccc0cc000000000
-- 134:00000000000000000ccc00cc0c0c0c0000c00ccc0c0c0c0c0ccc0ccc00000000
-- 135:00000000000000000ccc0ccc0c0c000c00c000c00c0c0c000ccc0c0000000000
-- 136:00000000000000000ccc0ccc0c0c0c0c00c000c00c0c0c0c0ccc0ccc00000000
-- 137:00000000000000000ccc0ccc0c0c0c0c00c00ccc0c0c000c0ccc0cc000000000
-- 138:00000000000000000ccc00550c0c050500c005050c0c05550ccc050500000000
-- 139:00000000000000000ccc05550c0c050500c005500c0c05050ccc055500000000
-- 140:00000000000000000ccc00550c0c050000c005000c0c05000ccc005500000000
-- 141:00000000000000000ccc05500c0c050500c005050c0c05050ccc055000000000
-- 142:00000000000000000ccc05550c0c050000c005500c0c05000ccc055500000000
-- 143:00000000000000000ccc05550c0c050000c005500c0c05000ccc050000000000
-- 144:00000000000000000ccc0eee0c0c0e0e0ccc0e0e000c0e0e0cc00eee00000000
-- 145:00000000000000000ccc00c00c0c0cc00ccc00c0000c00c00cc00ccc00000000
-- 146:00000000000000000ccc0cc00c0c000c0ccc00c0000c0c000cc00ccc00000000
-- 147:00000000000000000ccc0cc00c0c000c0ccc00c0000c000c0cc00cc000000000
-- 148:00000000000000000ccc000c0c0c00cc0ccc0c0c000c0ccc0cc0000c00000000
-- 149:00000000000000000ccc0ccc0c0c0c000ccc0ccc000c000c0cc00cc000000000
-- 150:00000000000000000ccc00cc0c0c0c000ccc0ccc000c0c0c0cc00ccc00000000
-- 151:00000000000000000ccc0ccc0c0c000c0ccc00c0000c0c000cc00c0000000000
-- 152:00000000000000000ccc0ccc0c0c0c0c0ccc00c0000c0c0c0cc00ccc00000000
-- 153:00000000000000000ccc0ccc0c0c0c0c0ccc0ccc000c000c0cc00cc000000000
-- 154:00000000000000000ccc00550c0c05050ccc0505000c05550cc0050500000000
-- 155:00000000000000000ccc05550c0c05050ccc0550000c05050cc0055500000000
-- 156:00000000000000000ccc00550c0c05000ccc0500000c05000cc0005500000000
-- 157:00000000000000000ccc05500c0c05050ccc0505000c05050cc0055000000000
-- 158:00000000000000000ccc05550c0c05000ccc0550000c05000cc0055500000000
-- 159:00000000000000000ccc05550c0c05000ccc0550000c05000cc0050000000000
-- 160:000000000000000000550eee05050e0e05050e0e05550e0e05050eee00000000
-- 161:0000000000000000005500c005050cc0050500c0055500c005050ccc00000000
-- 162:000000000000000000550cc00505000c050500c005550c0005050ccc00000000
-- 163:000000000000000000550cc00505000c050500c00555000c05050cc000000000
-- 164:00000000000000000055000c050500cc05050c0c05550ccc0505000c00000000
-- 165:000000000000000000550ccc05050c0005050ccc0555000c05050cc000000000
-- 166:0000000000000000005500cc05050c0005050ccc05550c0c05050ccc00000000
-- 167:000000000000000000550ccc0505000c050500c005550c0005050c0000000000
-- 168:000000000000000000550ccc05050c0c050500c005550c0c05050ccc00000000
-- 169:000000000000000000550ccc05050c0c05050ccc0555000c05050cc000000000
-- 170:0000000000000000005500550505050505050505055505550505050500000000
-- 171:0000000000000000005505550505050505050550055505050505055500000000
-- 172:0000000000000000005500550505050005050500055505000505005500000000
-- 173:0000000000000000005505500505050505050505055505050505055000000000
-- 174:0000000000000000005505550505050005050550055505000505055500000000
-- 175:0000000000000000005505550505050005050550055505000505050000000000
-- 176:000000000000000005550eee05050e0e05500e0e05050e0e05550eee00000000
-- 177:0000000000000000055500c005050cc0055000c0050500c005550ccc00000000
-- 178:000000000000000005550cc00505000c055000c005050c0005550ccc00000000
-- 179:000000000000000005550cc00505000c055000c00505000c05550cc000000000
-- 180:00000000000000000555000c050500cc05500c0c05050ccc0555000c00000000
-- 181:000000000000000005550ccc05050c0005500ccc0505000c05550cc000000000
-- 182:0000000000000000055500cc05050c0005500ccc05050c0c05550ccc00000000
-- 183:000000000000000005550ccc0505000c055000c005050c0005550c0000000000
-- 184:000000000000000005550ccc05050c0c055000c005050c0c05550ccc00000000
-- 185:000000000000000005550ccc05050c0c05500ccc0505000c05550cc000000000
-- 186:0000000000000000055500550505050505500505050505550555050500000000
-- 187:0000000000000000055505550505050505500550050505050555055500000000
-- 188:0000000000000000055500550505050005500500050505000555005500000000
-- 189:0000000000000000055505500505050505500505050505050555055000000000
-- 190:0000000000000000055505550505050005500550050505000555055500000000
-- 191:0000000000000000055505550505050005500550050505000555050000000000
-- 192:000000000000000000550eee05000e0e05000e0e05000e0e00550eee00000000
-- 193:0000000000000000005500c005000cc0050000c0050000c000550ccc00000000
-- 194:000000000000000000550cc00500000c050000c005000c0000550ccc00000000
-- 195:000000000000000000550cc00500000c050000c00500000c00550cc000000000
-- 196:00000000000000000055000c050000cc05000c0c05000ccc0055000c00000000
-- 197:000000000000000000550ccc05000c0005000ccc0500000c00550cc000000000
-- 198:0000000000000000005500cc05000c0005000ccc05000c0c00550ccc00000000
-- 199:000000000000000000550ccc0500000c050000c005000c0000550c0000000000
-- 200:000000000000000000550ccc05000c0c050000c005000c0c00550ccc00000000
-- 201:000000000000000000550ccc05000c0c05000ccc0500000c00550cc000000000
-- 202:0000000000000000005500550500050505000505050005550055050500000000
-- 203:0000000000000000005505550500050505000550050005050055055500000000
-- 204:0000000000000000005500550500050005000500050005000055005500000000
-- 205:0000000000000000005505500500050505000505050005050055055000000000
-- 206:0000000000000000005505550500050005000550050005000055055500000000
-- 207:0000000000000000005505550500050005000550050005000055050000000000
-- 208:000000000000000005500eee05050e0e05050e0e05050e0e05500eee00000000
-- 209:0000000000000000055000c005050cc0050500c0050500c005500ccc00000000
-- 210:000000000000000005500cc00505000c050500c005050c0005500ccc00000000
-- 211:000000000000000005500cc00505000c050500c00505000c05500cc000000000
-- 212:00000000000000000550000c050500cc05050c0c05050ccc0550000c00000000
-- 213:000000000000000005500ccc05050c0005050ccc0505000c05500cc000000000
-- 214:0000000000000000055000cc05050c0005050ccc05050c0c05500ccc00000000
-- 215:000000000000000005500ccc0505000c050500c005050c0005500c0000000000
-- 216:000000000000000005500ccc05050c0c050500c005050c0c05500ccc00000000
-- 217:000000000000000005500ccc05050c0c05050ccc0505000c05500cc000000000
-- 218:0000000000000000055000550505050505050505050505550550050500000000
-- 219:0000000000000000055005550505050505050550050505050550055500000000
-- 220:0000000000000000055000550505050005050500050505000550005500000000
-- 221:0000000000000000055005500505050505050505050505050550055000000000
-- 222:0000000000000000055005550505050005050550050505000550055500000000
-- 223:0000000000000000055005550505050005050550050505000550050000000000
-- 224:000000000000000005550eee05000e0e05500e0e05000e0e05550eee00000000
-- 225:0000000000000000055500c005000cc0055000c0050000c005550ccc00000000
-- 226:000000000000000005550cc00500000c055000c005000c0005550ccc00000000
-- 227:000000000000000005550cc00500000c055000c00500000c05550cc000000000
-- 228:00000000000000000555000c050000cc05500c0c05000ccc0555000c00000000
-- 229:000000000000000005550ccc05000c0005500ccc0500000c05550cc000000000
-- 230:0000000000000000055500cc05000c0005500ccc05000c0c05550ccc00000000
-- 231:000000000000000005550ccc0500000c055000c005000c0005550c0000000000
-- 232:000000000000000005550ccc05000c0c055000c005000c0c05550ccc00000000
-- 233:000000000000000005550ccc05000c0c05500ccc0500000c05550cc000000000
-- 234:0000000000000000055500550500050505500505050005550555050500000000
-- 235:0000000000000000055505550500050505500550050005050555055500000000
-- 236:0000000000000000055500550500050005500500050005000555005500000000
-- 237:0000000000000000055505500500050505500505050005050555055000000000
-- 238:0000000000000000055505550500050005500550050005000555055500000000
-- 239:0000000000000000055505550500050005500550050005000555050000000000
-- 240:000000000000000005550eee05000e0e05500e0e05000e0e05000eee00000000
-- 241:0000000000000000055500c005000cc0055000c0050000c005000ccc00000000
-- 242:000000000000000005550cc00500000c055000c005000c0005000ccc00000000
-- 243:000000000000000005550cc00500000c055000c00500000c05000cc000000000
-- 244:00000000000000000555000c050000cc05500c0c05000ccc0500000c00000000
-- 245:000000000000000005550ccc05000c0005500ccc0500000c05000cc000000000
-- 246:0000000000000000055500cc05000c0005500ccc05000c0c05000ccc00000000
-- 247:000000000000000005550ccc0500000c055000c005000c0005000c0000000000
-- 248:000000000000000005550ccc05000c0c055000c005000c0c05000ccc00000000
-- 249:000000000000000005550ccc05000c0c05500ccc0500000c05000cc000000000
-- 250:0000000000000000055500550500050505500505050005550500050500000000
-- 251:0000000000000000055505550500050505500550050005050500055500000000
-- 252:0000000000000000055500550500050005500500050005000500005500000000
-- 253:0000000000000000055505500500050505500505050005050500055000000000
-- 254:0000000000000000055505550500050005500550050005000500055500000000
-- 255:0000000000000000055505550500050005500550050005000500050000000000
-- </SPRITES>

-- <MAP>
-- 000:d67bd67b08002994d67b0800d67b299408002994299408009452d67b0800945229940800d67b6bbd080094526bbd0800d67bbdd608009452bdd6080029946bbd08002994bdd608006bbd6bbd08006bbdbdd608006bbd299408006bbdd67b08002994945208006bbd94520800d67b94520800945294520800bdd66bbd0800bdd629940800bdd6d67b4a29bdd694524a29ffffd67b4a29ffff94524a29bdd629949c42ffff29949c42bdd66bbd9c42ffff6bbd9c42bdd6bdd69c42ffffbdd69c426bbd29949c426bbd6bbd9c426bbdbdd69c42bdd6d67b9c426bbdd67b9c426bbd29944a296bbdd67b4a296bbd6bbd4a29
-- 001:6bbdbdd64a29bdd66bbd4a29bdd629944a29d67b29944a29299429944a29d67b6bbd4a2929946bbd4a29ffff2994de6bffff6bbdde6bbdd6bdd6de6bffffbdd6de6b6bbdbdd6de6bffffd67b9c42bdd694529c42ffff94529c42ffffd67bde6bbdd69452de6bffff9452de6b6bbd94524a296bbd94529c426bbd9452de6b9452d67b4a29945229944a2994526bbd4a29d67bbdd64a299452bdd64a292994bdd64a29299494524a29d67b94524a29945294524a299452d67b9c42945229949c4294526bbd9c42d67bbdd69c429452bdd69c422994bdd69c42299494529c42d67b94529c42945294529c429452d67bde6b
-- 002:94522994de6b94526bbdde6bd67bbdd6de6b9452bdd6de6b2994bdd6de6b29949452de6bd67b9452de6b94529452de6bbdd66bbdde6b6bbd6bbdde6bd67b6bbdde6b29946bbdde6bbdd62994de6b6bbd2994de6bd67b2994de6b29942994de6bbdd6d67bde6b6bbdd67bde6bd67bd67bde6b2994d67bde6b002000300010003000500010003000800060007000a00080007000c0009000b000e000c0003000e2007000f00020000100b000f000d000200021000100500031001000310020001000f0005100d0002100710001008100910071009100b1007100c100d100b100e100f100d100f1002200d100d1001200b1
-- 003:0012004200b10001006200f000010071007200720042005200b10042007100120072005200d0009200e0008200120022009200220032006100a2005100a200d0005100f000b20061008200b2006200f200c200d200b000d20040004000c20030007000f200b00002002300f100c1001300e100f10043003200e10033000200c1009100530081007300a10073009100a1007300830053006300a300730053000300c10081002100b3006300d30093008100c3006300a0000400800090002400a000310044001100500064004100c000140090006000e30050008000f300600041005400310004008400f300e300f40064
-- 004:003400a40014001400b4002400f3007400e3005400d40044006400e400540024009400040074008500f400c4003500a400a4004500b400840005007400e4006500d400f4007500e400b400250094009400150084004400210011004400c300b300d400d300c300e0003400c000c400920032005500320043004300c50055005500b50035002300a5004300a5000600c500c500f500b5009500e500a500e5004600060006003600f500d5002600e500b50045003500b50015002500f500050015008500360075003600650075004600d300650026009300d3001600a3009300160003008300d500130003003300950023
-- 005:0020004000300030006000500030007000800070009000a0007000b000c000b000d000e0003000c200e200f00040002000b0004000f000200011002100500041003100310011002000f000610051002100810071008100a10091009100c100b100c100e100d100e1000200f100f10032002200d10022001200120052004200010072006200720071004200120062007200d000820092008200620012009200820022006100b200a200a2008200d000f0006200b2008200a200b200f200e200c200b000f200d2004000d200c2007000e200f200020033002300c10003001300f10023004300e100130033008100630073
-- 006:007300530091007300a300830063009300a3005300830003006300c300d3008100b300c300a000240004009000140024003100540044005000e3006400c000340014006000f300e30080000400f300410064005400040094008400e3007400f4003400c400a4001400a400b400f300840074005400e400d4006400f400e4002400b4009400740005008500c40055003500a40035004500840015000500e40075006500f40085007500b400450025009400250015004400b30021004400d400c300d4006500d300e00092003400c400340092005500c40032004300a500c5005500c500b50023009500a500a500e50006
-- 007:00c5000600f5009500d500e500e50026004600060046003600d50016002600b50025004500b500f5001500f5003600050085000500360036004600650046002600d30026001600930016008300a3001600d5000300d500950013003300130095080804040408080404080808080804040408080804040408040808040404040808040404000804040804040808080404080808040404080808040404080808040408080404040408080404040408080404040408080404040808040404080808040404080808040404080804040808080804040808080404080808040008040404080404040808040404040400080004
-- 008:000804040408040800040404040800040404000804040408000804040408040408080408080404080808000400080408000400080404040800040008000804040408040800040008000804040804040804040008040404080004000800080404040800080404040800080404040808040404040800040404080804040804040800040008040800040008000804040408000400080408000400080004000800040008040404080004000804080004000804080004000804080004000804080004000800080404040804040408040800040008040800040008040800040008040800040008040800040008000804040408
-- 009:040404080408000400080408000400080004000800080408000804040408000400080004000404080404080404080404080404080404080404080804040804040804040804040804040804040804040804040804040804040804040804040808040408040804040804040804040804040408080408080404080804080404080804080404080804080404080804080408080408080408080408080804040804040804040408040804080808080404040808080808080808040804040800040808000400080008000400040804040400040004000400040004000400040008040404040004040404040404040404040404
-- 010:04040404040400040404040400040004000400080008080808080808080808080808080808080808040808080808080408040804080404040404080800100020003000400050006000700080009000a000b000c000d000e000f00001001100210031004100d00051006100710081009100a100b100c100d100e100f1000200120022003200420052006200720082009200a200b200c200d200e200f2000300130023003300430053006300730083009300a300b300c300d300e300f30004004200140082002400340044005400e3006400f200c300740084009400a400b400c400d400e400f400050015002500350045
-- 011:0035009400450055006500750085009500a500b500c500d5000100e500f500060016003100260036000100460056006600760086009600a600b600c600d600e6004600f60007001700270037004700570007006700770087009700a700b700c700d700e700f70008007200180028003800480058006800780088009800a800b800c800d800e800f8000900500019002900390049005900900069007900c000890099002900a9001200b900c900d900e900f9000a001a002a003a004a005a006a007a008a009a00aa00ba00ca000a00da00ea00fa000b001b002b003b004b005b006b007b008b009b00ab00bb00cb00db
-- 012:00eb00fb000c004b001c002c003c004c005c006c007c008c009c007200ac00bc006800cc00dc00ec00fc00b4000d001d002d00f40015003d004d005d006d007d008d009d00ad00bd00cd00dd005d00ed00fd000e001e002e003e004e005e006e007e008e009e00ae00be00ce00de00ee00fe000f001f002f003f004f005f006f007f008f009f00af00bf00cf00df00ef00ff100010101020103010401050106010701080109010a010b010c010d010e010f0100100101011002000401021005000701031008000a0104100b000d0105100e000011061001100310016004100511071006100810006009100b1000900c1
-- 013:00e1108100f1001210910022004210a1005200720058008200a210b100b200d200f600e2000310c10013003310d10043006300150073009300e400a300c310e100d300f310f1000400341002004400c300a500740094101200a400c4102200d400f41032000500251042003500351012009400551052006500851062009500b5004100c50001003600e5000610720016002610820036004600e6005600761092008600a6100100b600d610a200e6002710b20037005700170007007710c2008700a710d200b700d710e200e7002810f20038005800cc006800881003009800b8101300c800e8102300f8005010330019
-- 014:00391043004900901053006900c0106300890029001900a900b9107300c900e9108300f9001a1093002a004a10a3005a007a10b3008a00aa10c300ba000a00f900da00fa10d3000b002b10e3003b005b008d006b008b00bd009b00bb008f00cb00eb10f300fb004b003b001c003c001f004c006c005f007c009c0018007200bc1004006800dc101400ec00b400a4000d002d102400f4003d1034004d006d1044007d009d105400ad00cd106400dd00ed107400fd001e1084002e004e1094005e007e10a4008e00ae10b400be00de10c400ee000f10d4001f003f10e4004f006f10f4007f009f10e300af00cf100500df
-- 015:00ff1015100010201025103010501035106010801045109010b0105510c010e0106510f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:9452945208006bbd945208009452bdd608006bbdbdd60800bdd694524a29bdd6d67b4a296bbdd67b0800ffff94524a29ffffd67b4a29bdd629949c42ffff29949c42ffffbdd69c426bbdbdd69c426bbd29949c42bdd6d67b9c426bbdd67b9c42ffffbdd6de6bffff9452de6bffffbdd64a29ffff94524a299452bdd6de6bffffbdd608009452bdd6080094529452de6b945294520800d67b6bbd080029946bbd0800299429940800d67b29940800d67b6bbd4a2929946bbd4a29299429944a29d67b29944a29ffff945208006bbdbdd608006bbd6bbd08006bbd6bbd9c426bbd299408006bbd29944a296bbd6bbd4a29
-- 018:bdd66bbd4a29bdd629944a29bdd629940800bdd66bbd0800002000300010006000200050005000900060009000a0006000d000b000c000e000f000a0001100410021005100610011008100300051007000e00062006000010070006000a000f000810011002100a100f100b100c1001200d100b1000200c100d100e100a100f100120002002000400030006000700020005000800090009000b000a000d000e000b000e0000100f000110031004100510071006100810091003000d000420052006000f0000100810051001100a100e100f100c10002001200b100f1000200d1001200e100f100e10012009100210022
-- 019:008200e0005200b2007200a200b2009200c2008200c2009200c2006200b2008200a200720070000100e000d0003200420091008100210082007200e000b20062007200b200a200920082004200c200c2004200620082009200a2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:c300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f3003020000f0000
-- </SFX>

-- <SCREEN>
-- 000:dccccccdddddeeeecccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedccdeeffffffffffeffffffeffffffffffeeefffffeeffffffffffeeffffffeddddccccdccccccccccccccccccccccccccddfffffffccccccccdeccccccccccccccccccccccd
-- 001:dcccccccccdddddeeeeecccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedccccdeeffffffeffffffffffeffffffeeeffffffffeeeffffffeffffffffdddcccccccdccccccccccccccccccccccccccddfffffffecccccccdeccccccccccccccccccccccd
-- 002:dcccccccccccccddddeeeeeccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedccccccdeeffeffffffffffffffeffeeeffffffffffffeefffefffffffddddcccccccccdccccccccccccccccccccccccccddffffffffcccccccdeccccccccccccccccccccccd
-- 003:dccccccccccccccccdddddeeeecceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedccccccccdeeffffffffffffffffeeefffffffffffffffeeefffffffdddccccccccccccdccccccccccccccccccccccccccddffffffffeccccccdeccccccccccccccccccccccd
-- 004:dccccccccccccccccccccddddeeeeeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedccccccccccdeeffffffffffffeeefeffffffffffffffeffeefffddddccccccccccccccdccccccccccccccccccccccccccddfffffffffccccccdeccccccccccccccccccccccd
-- 005:dcccccccccccccccccccccccdddddeddeccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccdeeffffffffeeefffffeffffffffffefffffeedddcccccccccccccccccdccccccccccccccccccccccccccddfffffffffecccccdeccccccccccccccccccccccd
-- 006:dccccccccccccccccccccccccccddeddeeeecccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccdeeffffeeefffffffffeffffffefffffffdedcccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccd
-- 007:dccccccccccccccccccccccccccceedddddeeeeecccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccdeeeeeffffffffffffeffefffffffddddeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccd
-- 008:dccccccccccccccccccccccccccceeddccdddddeeeeccccccccccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccdeeffffffffffffffeeffffffdddccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccd
-- 009:dccccccccccccccccccccccccccceeddccccccddddeeeecccccccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdcccccccceddeeffffffffffeffffefdddcccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccd
-- 010:dccccccccccccccccccccccccccceeddcccccccccdddddeeeecccdcccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccdefffffffeffffffdddcccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccd
-- 011:dccccccccccccccccccccccccccceeddcccccccccccccddddeeeeccccccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccccdeffefffffffddccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccccccc
-- 012:dccccccccccccccccccccccccccceeddccccccccccccccccddddeeeecccccccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccccccdefffffdddccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccccccceeee
-- 013:dccccccccccccccccccccccccccceeddccccccccccccccccccccddddeeeecccccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccccccccdefdddccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccccccceeeeeddd
-- 014:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccddddeeeeccccccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccccccccdddcccccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffcccccdeccccccccccceeeeedddddcc
-- 015:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccdddeeeecccccedccccccccccccccdcccccccccccedcccccccccdccccccccedccccccdddcccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfeffffffffcccccdeccccccceeeedddddccccccd
-- 016:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdccccccccddddeeeccedccccccccccccccdcccccccccccedcccccccccdccccccccedcccdddccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffefffffffcccccdecceeeeedddddccccccccccd
-- 017:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccddddeeedccccccccccccccdcccccccccccedcccccccccdccccccccedcdddccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffeeffffffcccccdeeeeddddcccccccccccccccd
-- 018:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccddddeeecccccccccccdcccccccccccedcccccccccdcccccccceddcccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffeffffffceeeeeddddcccccccccccccccccccd
-- 019:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdccccccccccccccccceddddeeeccccccccdcccccccccccedcccccccccdccccccdddeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffefffffeeeeeeeccccccccccccccccccccccd
-- 020:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedcccdddeeeeccccdcccccccccccedcccccccccdccccddccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffeffffeffffeeccccccccccccccccccccccd
-- 021:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccddddeeecccccccccccccedcccccccccdcdddccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffefffffffffeeccccccccccccccccccccccd
-- 022:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccdddeeeccccccccccedcccccccccddcccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffeffffffffeeccccccccccccccccccccccd
-- 023:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedcccccccccccccdddeeeeccccccedcccccccddcccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffefffffffeeccccccccccccccccccccccd
-- 024:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedcccccccccccccccccdddeeecccedccccddccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffeffffffeeccccccccccccccccccccccd
-- 025:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccdddeeeedccddccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffeffffffeeccccccccccccccccccccccd
-- 026:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdcccccccccdddddcccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffefffffeeccccccccccccccccccccccd
-- 027:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 028:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccccccccccccccedccccccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 029:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccccdddddcccccccedccccccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 030:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdcccdddddddddddcccedccccccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 031:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdccdddddddddddddddddccccccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 032:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdddddcddddcccdddddddddddccccccccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 033:dccccccccccccccccccccccccccceeddcccccccccccccccccccccdddcccddddccccccccdddddddddddcccccdccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 034:dccccccccccccccccccccccccccceeddcccccccccccccccccccddddccccddddcccccccccccccddddddddddddccccccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 035:dccccccccccccccccccccccccccceeddccccccccccccccccccdddccccccddddcccccccccccccccccdddddddddddcccccccceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffeeffeeccccccccccccccccccccccd
-- 036:dccccccccccccccccccccccccccceeddccccccccccccccccddddcccccccddddccccccccccccccccccccccddddddddd999cceeccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddffffffffffeefffeeccccccccccccccccccccccd
-- 037:dccccccccccccccccccccccccccceeddcccccccccccccccdddcccccccccddddcccccccccccccccccccccccccccd99999999deccccccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 038:dccccccccccccccccccccccccccceeddcccccccccccccdddcccccccccccddddccccccccccccccccccccccccccc99999889999ddddccccccccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 039:dccccccccccccccccccccccccccceeddcccccccccccddddccccccccccccddddcccccccccccccccccccccccccc9999888888999ddddddddcccccccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccccddfffffffffffffffeeccccccccccccccccccccccd
-- 040:dccccccccccccccccccccccccccceeddccccccccccdddccccccccccccccddddcccccccccccccccccccccccc999998888888899cccdddddddddcccccdeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccccccccccceddeffffffffffffffeeccccccccccccccccccccccd
-- 041:dccccccccccccccccccccccccccceeddccccccccdddccccccccccccccccddddccccccccccccccccccccccc99999888888888899cccccccddddddddddeccccccccccccdcccccccccccccccdeccccccccccccccccccccdccccccccccccccccceeeeeeeeeedeefffffffffffffeeccccccccccccccccccccccd
-- 042:dccccccccccccccccccccccccccceeddccccccccddcccccccccccccccccddddccccccccccccccccccccccca99988888888888999cccccccccccdddddeccccccccccccdcccccccccccccccdeccccccccccccccccccccccccccccccceeeeeeeeeeeeedddddeeeefffffffffffeeccccccccccccccccccccccd
-- 043:cccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccccccc99898888888888888999cccccccccccccceeccccccccccccdcccccccccccccccdecccccccccccccccccccccccceeeeeeeeeeeedddddddddddddeeeeeffffffffffeeccccccccccccccccccccccd
-- 044:eeeeeccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccccccc9a8888888888888888999ccccccccccccceeccccccccccccdcccccccccccccccdeccccccccccccccccceeeeeeeeeeedddddddddddddccccccddffeeeefffffffffeeccccccccccccccccccccccd
-- 045:eeeeeeeeeeeeeeeccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccccc99a88888888888888888a9ccccccccccccceeccccccccccccdcccccccccccccccdecccccccccceeeeeeeeee222ddddddddddccccccccccccccddfffeeeeefffffffeeccccccccccccccccccccccd
-- 046:ddddddddddeeeeeeeeeeeeeeeccceeddcccccccccccccccccccccccccccddddccccccccccccccccccccca9888888888888888888899cccccccccccceeccccccccccccdcccccccccccccccdeccceeeeeeeeeeddddd2222222ccccccccccccccccccccccddfffffeeeeffffffeeccccccccccccceeeeeeeeee
-- 047:cccccddddddddddddddddeeeeeeeeeddeeeccccccccccccccccccccccccddddcccccccccccccccccccc9a988888888888888888889acccccccccccceeccccccccccccdccccccccccccceedeeeeeeddddddddddd2211111322cccccccccccccccccccccddffffffeeeefffffeecceeeeeeeeeeeeeefffffff
-- 048:cccccccccccccccccdddddddddddddddeeeeeeeecccccccccccccccccccddddcccccccccccccccccccc998888888888888888888889cccccccccccceecccccccccccccccccceeeeeeeeeeeddddddddddcccccc2211111112222cccccccccccccccccccddffffffffeeeeeeeeeeeeeffffffffffffffffffe
-- 049:dcccccccccccccccccccccccccccdeddddddddddcccccccccccccccccccddddcccccccccccccccccccc9a888888888888888888888acccccccccccceeccccccccccceeeeeeeeeeefffffffecccccccccccccc221111111111222ccccccccccccccccccddffffffffffeffffffffffffffffffffffffffffe
-- 050:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccccca98888888888888888888888cccccccccccceecccceeeeeeeeeefffffffffffffffeccccccccccccc2211111111111132ccccccccccccccccccddffffffffffeffffffffffffffffffffffffffffe
-- 051:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccca9888888888888888888888889ccccccccccceeeeeeeefffffffffffeeffffffffffecccccccccccc221111111111111123cccccccccccccccccddfffffffffeeffffffffffffffffffffffffffffe
-- 052:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccc9a88888888888888888888888accccccccccceddeffffffffffffffffffeeffeffffecccccccccccc2111111111111111122ccccccccccccccccddfffffffffeeffffffffffffffffffffffffffffe
-- 053:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccca9888888888888888888888889cccccccccccedddddddddeefefffffffffffffffffecccccccccccc3111111111111111132ccccccccccccccccddfffffffffeeffffffffffffffffffffffffffffe
-- 054:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccc9a88888888888888888888888a9ccccccccccedcccccccccdddddddefffffeddddddeccccccccccc21111111111111111113ccccccccccccccccddfffffffffefffffffffffffffffffffffffffffe
-- 055:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccca9a888888888888888888888889accccccccccedcccccccccccccccccdddddcccccccecccccccccc321111111111111111113ccccccccccccccccddfffffffffefffffffffffffffffffffffffffffe
-- 056:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa88888888888888888888888899ccccccccccedcccccccccccccccccceecccccccccecccccccccc2311111111111111111112cccccccccccccccddffffffffeefffffffffffffffffffffffffffffe
-- 057:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccca98888888888888888888888888accccccccccedcccccccccccccccccceecccccccccecccccccccc2111111111111111111113cccccccccccccccddffffffffeefffffffffffffffffffffffffffffe
-- 058:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa8888888888888888888888888aacccccccccedcccccccccccccccccceeccccccccceccccccccc23111111111111111111112cccccccccccccccddffffffffeefffffffffffffffffffffffffffffe
-- 059:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccca98888888888888888888888888a9cccccccccedcccccccccccccccccceeccccccccceccccccccc321111111111111111111133ccccccccccccccddffffffffeefffffffffffffffffffffffffffffe
-- 060:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa8888888888888888888888888aacccccccccedcccccccccccccccccceeccccccccceccccccccc311111111111111111111132ccccccccccccccddffffffffeffffffffffffffffffffffffffffffe
-- 061:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccc99a88888888888888888888888888a9cccccccccedcccccccccccccccccceeccccccccceccccccccc211111111111111111111123ccccccccccccccddfffffffeeffffffffffffffffffffffffffffffe
-- 062:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888acccccccccedcccccccccccccccccceeccccccccceccccccccc311111111111111111111132ccccccccccccccddfffffffeeffffffffffffffffffffffffffffffe
-- 063:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceeccccccccceccccccccc3111111111111111111111123cccccccccccccddfffffffeeffffffffffffffffffffffffffffffe
-- 064:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc21111111111111111111111133cccccccccccccddfffffffeeffffffffffffffffffffffffffffffe
-- 065:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc31111111111111111111111123cccccccccccccddfffffffefffffffffffffffffffffffffffffffe
-- 066:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc31111111111111111111111133cccccccccccccddffffffeefffffffffffffffffffffffffffffffe
-- 067:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc21111111111111111111111133cccccccccccccddffffffeefffffffffffffffffffffffffffffffe
-- 068:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc31111111111111111111111133cccccccccccccddffffffeefffffffffffffffffffffffffffffffe
-- 069:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888888aaccccccccedcccccccccccccccccceecccccccccecccccccc31111111111111111111111133cccccccccccccddfeeeeeeeffeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 070:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa888888888888888888888888889aaccccccccedcccccccccccccccccceecccccccccecccccccc32111111111111111111111233cccccccccccccddfeeeeeeffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 071:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa988888888888888888888888889aaccccccccedcccccccccccccccccceecccccccccecccccccc32211111111111111111111233cccccccccccccddfffffeeffffffffffffffffffffffffffffffffe
-- 072:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa988888888888888888888888899aaccccccccedcccccccccccccccccceecccccccccecccccccc42221111111111111111112233cccccccccccccddfffffeeffffffffffffffffffffffffffffffffe
-- 073:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa998888888888888888888888899aaccccccccedcccccccccccccccccceecccccccccecccccccc32222211111111111111122233cccccccccccccddfffffeeffffffffffffffffffffffffffffffffe
-- 074:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa999888888888888888888888999aaccccccccedcccccccccccccccccceecccccccccecccccccc32222221111111111112222243cccccccccccccddfffffeeffffffffffffffffffffffffffffffffe
-- 075:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa999988888888888888888899999aaccccccccedcccccccccccccccccceeccccccccceccccccccc3222222211111122222222233cccccccccccccddfffffefffffffffffffffffffffffffffffffffe
-- 076:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa999999988888888888888999999aaccccccccedcccccccccccccccccceeccccccccceccccccccc422222222222222222222233ccccccccccccccddffffeefffffffffffffffffffffffffffffffffe
-- 077:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa999999998888888888888999999baccccccccedcccccccccccccccccceeccccccccceccccccccc322222222222222222222234ccccccccccccccddffffeefffffffffffffffffffffffffffffffffe
-- 078:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccaaa99999999999888888899999999aacccccccccedcccccccccccccccccceeccccccccceccccccccc322222222222222222222243ccccccccccccccddffffeefffffffffffffffffffffffffffffffffe
-- 079:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccbba99999999999999999999999999abcccccccccedcccccccccccccccccceeccccccccceccccccccc432222222222222222222234ccccccccccccccddffffeefffffffffffffffffffffffffffffffffe
-- 080:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa9999999999999999999999999aacccccccccedcccccccccccccccccceeccccccccceccccccccc432222222222222222222233ccccccccccccccddffffeefffffffffffffffffffffffffffffffffe
-- 081:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccab9999999999999999999999999abcccccccccedcccccccccccccccccceeccccccccceccccccccc34222222222222222222224cccccccccccccccddfffeeffffffffffffffffffffffffffffffffffe
-- 082:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa9999999999999999999999999aacccccccccedcccccccccccccccccceeeccccccccecccccccccc3422222222222222222223cccccccccccccccddfffeeffffffffffffffffffffffffffffffffffe
-- 083:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa999999999999999999999999baccccccccccedccccccccccceeeeeeefffeeeeeeeeecccccccccc3422222222222222222224cccccccccccccccddfffeeffffffffffffffffffffffffffffffffffe
-- 084:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccab999999999999999999999999abccccccccccedcccceeeeeeeefffffffffffffffffeccccccccccc32222222222222222224ccccccccccccccccddfffeeffffffffffffffffffffffffffffffffffe
-- 085:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddccccccccccccccccccaa999999999999999999999999baccccccccccedeeeeeffffffffffffeffffffffeffeccccccccccc42222222222222222223ccccccccccccccccddfffeeffffffffffffffffffffffffffffffffffe
-- 086:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccccba99999999999999999999999abcccccccccceeeefffffffffffffffffffeffeefffecccccccccccc4222222222222222234ccccccccccccccccddffeefffffffffffffffffffffffffffffffffffe
-- 087:dccccccccccccccccccccccccccceeddcccccccccccccccccccccccccccddddcccccccccccccccccccab99999999999999999999999bcccccccccccefffffffeeeffffffeeffffffffffffecccccccccccc3422222222222222444ccccccccccccccccddffeefffffffffffffffffffffffffffffffffffe
-- 088:dccccccccccccccccccccccccccceeddcccccccecccccccccccccccccccddddcccccccccccccccccccba99999999999999999999999acccccccccccefffffffffffefeeeefffffffffffffecccccccccccc444222222222222244cccccccccccccccccddffeefffffffffffffffffffffffffffffffffffe
-- 089:dccccccccccccccccccccccccccceeddeeeeeeeecccccccccccccccccccddddcccccccccccccccccccbb99999999999999999999999bccccccccccceffffffeeffffffffffffeeefffffffecccccccccccccc422222222222234ccccccccccccccccccddffeefffffffffffffffffffffffffffffffffffe
-- 090:dccccccccccccccccccceeeeeeeeeedeeeffffffcccccccccccccccccccddddcccccccccccccccccccabb999999999999999999999acccccccccccceeeffffffffffffffffffffffffeeeeeeeeeeeccccccccc42222222223444ccccccccccccccccccddffeefffffffffffffffffffffffffffffffffffe
-- 091:cccccccccceeeeeeeeeeeeeeeffffeeeefffffffcccccccccccccccccccddddccccccccccccccccccccab999999999999999999999bccccccccccccefffeeffffffffffffffffffffeeeeffffeeeeeeeeeeecc444222222444ccccccccccccccccccccddfeeffffffffffffffffffffffffffffffffffffe
-- 092:eeeeeeeeeeeeeeeeffffffffffffffeeeeffffffcccccccccccccccccccddddccccccccccccccccccccba99999999999999999999bacccccccccccceffffffffeefffffffffffeeeeffffffffffffffeeeeeeee4442224444cccccccccccccccccccccddfeeffffffffffffffffffffffffffffffffffffe
-- 093:eeeeeeeffffffffffffffffffffffffeeeeeffefcccccccccccccccccccddddccccccccccccccccccccbb99999999999999999999bbccccccccccccefffffffffffffeeffeeeefffffffffffffffffffffffffeee444444eeeccccccccccccccccccccddfeeffffffffffffffffffffffffffffffffffffe
-- 094:effffffffffffffffffffffffffffeeffeeeefffcccccccccccccccccccddddcccccccccccccccccccccab9999999999999999999bcccccccccccccefffffffffffffeeeefffeffffffffffffffffffffffffffffeffe4eeeeeeeeeeecccccccccccccddfeeffffffffffffffffffffffffffffffffffffe
-- 095:effffff00000000000000000f00000000000000fccccccccccccccc00000000000000cccccccccccccccbb999999999999999999abcccccc00000000fffffffffeeeeeffffffffffe00000000fffffffffffffeeeffffffffffeeeeeeeeeeeeeccccccddfeeffffffffffffffffffffffffffffffffffffe
-- 096:effffff0ccccccccccccccc0f0cccccccccccc0eccccccccccccccc0cccccccccccc0ccccccccccccccccba9999999999999999bbccccccc0cccccc0fffffeeeeefffffffffffffff0cccccc0fffffffffffeefffffffffffffffffffeeeeeeeeeeeeeddeeeffffffffffffffffffffffffffffffffffffe
-- 097:efffffe0ccccccccccccccc0f0cccccccccccc0eecccccccccccccc0cccccccccccc0ccccccccccccccccbb999999999999999bbbccccccc0cccccc0feeeeefffffffffffffffffff0cccccc0feeeffffeefffffffffffffffffffffffffffffeeeeeeedeeeeeeeeeffffffffffffffffffffffffffffffe
-- 098:effffff0ccccccccccccccc0f0cccccccccccc0000ecccccccccccc0cccccccccccc0000cccc00000000000bb9900000000000000cccc0000cccccc0000000ffff00000000000000f0cccccc0fffffeeeef00000000000000ffffffffffffffffffffeeeeeeeeeeeeeeeeeeefffffffffffffffffffffffe
-- 099:effffff0000000000cccccc0f0cccccc000000ccc0eeccccccccccc0cccccc000000ccc0cccc0ccccccccc0bbb90cccccccccccc0ccce0ccccccccccccccc0efff0cccccccccccc0f0cccccc0fffeefffff0cccccccccccc0fffffffffffffffffffeeeeeffffeeeeeeeeeeeeeeeeeefffffffffffffffff
-- 100:efffffffffffffff0cccccc0e0cccccc0ffff0ccc0eeecccccccccc0cccccc0cccc0ccc0cccc0ccccccccc0bbbb0cccccccccccc0eeee0ccccccccccccccc0eeee0cccccccccccc0f0cccccc0eeefffffff0cccccccccccc0ffffffffffffffffffeeeeefffffffffffeeeeeeeeeeeeeeeeeeeffffffffff
-- 101:effffffffffff0000cccccc0f0cccccc0ffff0ccc0eeeeecccccccc0cccccc0cccc0ccc0c0000ccccccccc0000b0cccccccccccc0000e0ccccccccccccccc0f0000cccccccccccc0f0cccccc0fffffff0000cccccccccccc0efffffffffffffffeeeeeefffffffffffffffffffeeeeeeeeeeeeeeeeeeefff
-- 102:efffffffffeee0cccccc0000f0cccccc0ffff0ccc0feeeeeccccccc0cccccc0cccc0ccc0c0cccccc000000ccc0b0cccccc000000ccc0f0000cccccc0000000f0ccc000000cccccc0f0cccccc0fffffff0ccccccccc0000000fffeeefffffffffeeeeefffffffffffffffffffffffffffeeeeeeeeeeeeeeee
-- 103:fffeeeeeeffff0cccccc0ffff0cccccc0ffff0ccc0ffeeeeeeccccc0cccccc0cccc0ccc0c0cccccc0cccc0ccc0c0cccccc0eeee0ccc0ffff0cccccc0fffffff0ccc0ffff0cccccc0f0cccccc0fffffff0ccccccccc0fffffffffffffffefffeeeeeefffffffffffffffffffffffffffffffffffeeeeeeeee
-- 104:eeeffff00000f0cccccc0000f0cccccc0ffff0ccc0fffeeeeeecccc0cccccc000000ccc0c0cccccc0cccc0ccc0e0cccccc0ffff0ccc0ffff0cccccc0fffffff0ccc0ffff0cccccc0e0cccccc0fffffff0ccccccccc0000000ffffffffffffeeeeeeffffffffffffffffffffffffffffffffffffffffffeee
-- 105:eefffff0ccc0f0000cccccc0f0cccccc0ffff0ccc0efffeeeeeeccc0cccccccccccc0000c0cccccc0ccee0ccc0e0cccccc0efff00000ffff0cccccc0fffffff0ccc0ffff0cccccc0f0cccccc0fffffff0000000ccccccccc0fffffffffffeeeeeefffeefffffffffffffffffffffffffffffffffffffffee
-- 106:eefffff0ccc0ffff0cccccc0f0cccccc0fffe0ccc0ffffffeeeeeec0cccccccccccc0cccc0cccccc0eeee0ccc0e0cccccc0feeefffffffff0cccccc0fffffff0ccc0ffff0cccccc0f0cccccc0eefffffffffff0ccccccccc0fffffffffeeeeeefffffffffeeeffffffffffffffffffffffffffffffffffee
-- 107:eefffff0ccc000000cccccc0f0cccccc000000ccc0fffffffeeeeee0cccccccccccc0cccc0cccccc000000ccc0f0cccccc0fffeeeeffffff0cccccc0000000f0ccc000000cccccc0f0cccccc0000000f0000000ccccccccc0ffffffffeeeeeeffffffffffffffffeeeffffffffffffffffffffffffffffee
-- 108:eefffff0000ccccccccc0000f0cccccccccccc0000ffffffffeeeee0cccccc0000000ceee0000ccccccccc0000f0cccccc0ffffffeeeffff0000ccccccccc0f0000cccccccccccc0f0000ccccccccc0e0cccccccccccc0000ffffffeeeeeeeffffffffffffffffffffffeeefffffffffffffffffffffffee
-- 109:eeffffffff0ccccccccc0eeff0cccccccccccc0ffffffffffffeeee0cccccc0ccceeeeeeeeee0ccccccccc0ffff0cccccc0fffffffffeeeffff0ccccccccc0fffe0cccccccccccc0ffff0ccccccccc0f0cccccccccccc0ffffffffeeeeeeeffffffffffffffffffffffffffffeeeffffffffffffffffffee
-- 110:eeffffffff0ccccccccc0ffff0cccccccccccc0fffffffffffffeee0cccccc0eeeeeeeeeeeee0ccccccccc0ffff0cccccc0fffffffffffeeeef0ccccccccc0eeee0cccccccccccc0ffff0ccccccccc0f0cccccccccccc0fffffffeeeeeeeffffffffffffffffffffffffffffffffffeeeeffffffffffffee
-- 111:eefffffffe00000000000ffff00000000000000fffffffffffffffe00000000eeeeeeeeeffff00000000000ffff00000000ffffffffffffffee00000000000efff00000000000000ffff00000000000f00000000000000eefffeeeeeeefffffffffffffffffffffffffffffffffffffffffeeeefffffffee
-- 112:eeffeeeffffffffffffffffffffffffffffffffffffffffffffffffeeeeedeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffeeeeffeeeefffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffeeeffee
-- 113:eeffffffffffffff00000000ffffffffffffffffffffffffffffffffeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffee
-- 114:eeffffffffffffff0cccccc0ffffffffffffffffffffffffffffeeeeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffeeeffeeefffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffee
-- 115:eeffffffffffffff0cccccc0ffffffffffffffffffffffffeeeeeeeefffeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffeeeeffffffeeeefffffffffffffffffffffffffffffffffffffffffffffffeeeeeeefffeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffee
-- 116:eeffffffff0000000cccccc0ffff00000000000ffff00000000e00000fffeeee00000000000fffffffffffffffffffffffffffffffffffeeeeffffffffffffeeeeffffffffffffffffffffffffffffffffffffffffffeeeeeeeeffffffffeeeeeeeeffffffffffffffffffffffffffffffffffffffffffee
-- 117:eeffffffff0cccccccccccc0ffff0ccccccccc0feee0cccccc0f0ccc0ffffeee0ccccccccc0fffffffffffffffffffffffffffffffffeeeeffffffffffffffffeeeefffffffffffffffffffffffffffffffffffffffeeeeeeeefffffffffffffeeeeeeeeffffffffffffffffffffffffffffffffffffffee
-- 118:eeffffffff0cccccccccccc0ffff0ccccccccc0eeee0cccccc0f0ccc0fffffee0ccccccccc0ffffffffffffffffffffffffffffffeeeeffffffffffffffffffffffeeeeffffffffffffffffffffffffffffffffffeeeeeeeeefffffffffffffffffeeeeeeeeeffffffffffffffffffffffffffffffffffee
-- 119:eefffff0000cccccccccccc0f0000ccccccccc0000f0cccccc000ccc0000f0000ccccccccc0000ffffffffffffffffffffffffeeeeffffffffffffffffffffffffffffeeeeffffffffffffffffffffffffffffffeeeeeeeefffffffffffffffffffffffeeeeeeeeeffffffffffffffffffffffffffffffee
-- 120:eefffff0ccc000000cccccc0f0cccccc000cccccc0f0ccccccccccccccc0f0cccccc000000ccc0fffffffffffffffffffffeeeeeffffffffffffffffffffffffffffffffeeeeeffffffffffffffffffffffffffeeeeeeeeffffffffffffffffffffffffffffeeeeeeeeeffffffffffffffffffffffffffee
-- 121:eefffff0ccc0ffff0cccccc0e0cccccc0f0cccccc0f0ccccccccccccccc0f0cccccc0eeee0ccc0fffffffffffffffffffeeeeffffffffffffffffffffffffffffffffffffffeeeeffffffffffffffffffffffeeeeeeeeefffffffffffffffffffffffffffffffffeeeeeeeeeffffffffffffffffffffffee
-- 122:eefffff0ccc0ffff0cccccc0e0cccccc000cccccc0f0ccccccccccccccc0f0cccccc0eeee0ccc0ffffffffffffffffeeeeeffffffffffffffffffffffffffffffffffffffffffeeeeeffffffffffffffffffeeeeeeeeeffffffffffffffffffffffffffffffffffffffeeeeeeeeeffffffffffffffffffee
-- 123:eefffff0ccc0ffff0cccccc0e0ccccccccc0000000f0ccc000ccc000ccc0f0cccccc0eeee0ccc0fffffffffffffeeeeeffffffffffffffffffffffffffffffffffffffffffffffffeeeeefffffffffffffeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeffffffffffffffee
-- 124:eefffff0ccc0eeee0cccccc0f0ccccccccc0fffffff0ccc0f0ccc0f0ccc0f0cccccc0feee0ccc0effffffffffeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeffffffffffeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeffffffffffee
-- 125:eefffff0ccc000000cccccc0f0ccccccccc0000ffff0ccc0f0ccc0f0ccc0f0cccccc000000ccc0eeffffffeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeffffffeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeffffffee
-- 126:ffffeee0000cccccccccccc0f0000ccccccccc0ffff0ccc0f0ccc0f0ccc0f0000ccccccccc0000eeeefffffeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeffff
-- 127:eeeeeeeeee0cccccccccccc0ffff0ccccccccc0ffff0ccc0f0ccc0f0ccc0ffff0ccccccccc0eeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeee
-- 128:eeeeeeffff0cccccccccccc0ffff0ccccccccc0ffff0ccc0f0ccc0f0ccc0ffff0ccccccccc0eeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeee
-- 129:eeffffffff00000000000000ffff00000000000ffff00000f00000f00000ffff00000000000feeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffee
-- 130:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 131:eeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeefffffeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeefffffeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeee
-- 132:eeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeefffffffeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeefffffffeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeee
-- 133:eeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeefffffffffffeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeefffffffffffeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeee
-- 134:eeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeefffffffffffffffeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeefffffffffffffffeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeee
-- 135:eeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeffffffffffffffffffeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeffffffffffffffffffeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffeee
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

