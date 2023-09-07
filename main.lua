-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

package.path = "/home/pingu/tic80-folder/3d-renderer/?.lua"

require "project_files/meshes"

require "renderer"

require "project_files/libraries"

Objects={
 --[[]]
 {
 position={x=0,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.tic,
 originoffset={x=-3,y=0,z=0},
 },
 {
 position={x=0,y=3,z=0},
 rotation={x=0,y=180,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.tic,
 originoffset={x=-3,y=0,z=0},
 },
 {
 position={x=0,y=10,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=1,y=1,z=1},
 mesh=Meshes.heart,
 },
 {
 position={x=30,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.cube,
 },
 {
 position={x=-30,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.cube,
 },
 {
 position={x=0,y=3,z=-30},
 rotation={x=0,y=0,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.cube,
 },
 {
 position={x=0,y=0,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=1,y=2,z=1},
 mesh=Meshes.arena,
 },
 {
 position={x=1,y=-1.5,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=1,y=1,z=1},
 mesh=Meshes.gun,
 lock_to_camera=true
 },
 {
 position={x=0,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=7,y=7,z=7},
 mesh=Meshes.square,
 },
 {
 position={x=0,y=7,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=7,y=7,z=7},
 mesh=Meshes.text,
 text="hello world",
 color=0
 },
 {
 position={x=-17,y=0,z=17},
 rotation={x=0,y=0,z=0},
 scale={x=1,y=1,z=1},
 mesh=Meshes.terminal,
 buttoncolor=2,
 },--]]

}

for _,mesh in pairs(Meshes) do; if mesh.size~=false then
	local size=0
	for _,vert in pairs(mesh.verts) do
		size=math.max(size, Vector.GetLen(vert) )
	end
	mesh.size=size
end; end

Camera={position={x=0,y=3,z=-5},rotation={x=0,y=0,z=0},
CPlane=Renderer.CuttingPlanes.NearOnly
}

Bullets={}
Targets={
{
 position={x=0,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.tic,
},
{
 position={x=-10,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.tic,
},
{
 position={x=10,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale={x=2,y=2,z=2},
 mesh=Meshes.tic,
},
}

Gun=true

function TIC()
	T=(T and T+1) or 0



	Markinit()
	TotalTime=time()

	Renderer.resetScene()
	Gui_drawdump=Renderer.customScene()

	Renderer.addObjectsToScene(Objects)
	Renderer.addObjectsToScene(Bullets)
	Renderer.addObjectsToScene(Targets)
	--[[]]
	Renderer.addObjectsToScene({{
	 position={x=0,y=0,z=1},
	 rotation=Camera.rotation,
	 scale=.1,
	 mesh=Meshes.axis,
	 lock_to_camera=true,
	 rev_rot_order=true,
	 }},Gui_drawdump)
--]]
--[[]]
	Renderer.clipObjects()

	Renderer.transformVerts()
	Renderer.transformVerts(Gui_drawdump)


	Mark("VertDumpTime")

	Renderer.addDrawElements()
	Renderer.addDrawElements(Gui_drawdump)

	Renderer.replaceLabels()
	Renderer.replaceLabels(Gui_drawdump)
	Mark("TriDumpTime")



--[[]
		for _,origin in pairs(Renderer.data.objectorigins) do
			Renderer.data.drawdump[#Renderer.data.drawdump+1]={
			 origin[1]; nofverts=1,type="c",
			 data={p=1,b=true,c=12,s=origin[1].radius},object=origin.object
			}
		end--]]

	Renderer.clipScene()
	Renderer.clipScene(Gui_drawdump)
	Mark("TriClipTime")



	Renderer.sortScene()
	Renderer.sortScene(Gui_drawdump)
	Mark("TriSortTime")
--]]

	cls(11)
--[[]]
	--Camera.FOV=60
	--rect(60,136/4,120,68,11)
	Renderer.projectVerts({vertexdump=Renderer.data.scene.objectorigins})

	Renderer.drawScene()
	--rectb(60,136/4,120,68,0)
	Camera.FOV=120
	Renderer.drawScene(Gui_drawdump)

	Mark("TriDrawTime")
--]]
--[[
Renderer.fullDraw({})
Renderer.fullDraw({},Gui_drawdump)
-- ]]
	TotalTime=time()-TotalTime



	print("vertexes:"..Renderer.debug.vertexcount.."\ntris:"..#Renderer.data.scene.drawdump
	,1,1,15,false,1,true)

	if Markstr==nil or T%30==1 then

		Markstr="load:"..math.floor((
		TotalTime/(1000/60) )*100).."%"
		.."\n"..Markprint(function(name,value) return
		name..": "..value*1000//1/1000 .."ms." end)
		.."total: "..TotalTime*1000//1/1000 .."ms."

	end
	print(Markstr,1,13,15,false,1,true)

	Markclear()



local Vx,Vz=0,0

	Vy=Vy and Vy-.015 or 0

	local floor=3

	if	key(19)	then	Vz=-.2	end
	if	key(23)	then	Vz= .2	end
	if	key(4)	then	Vx= .2	end
	if	key(1)	then	Vx=-.2	end

	if	key(48)	and Camera.position.y<=floor then	Vy=0.5	end

	Vx,_,Vz=Vector.rotate(Vx,0,Vz,
		0,-math.rad(Camera.rotation.y),0)

	Camera.position.x,Camera.position.y,Camera.position.z=
	Camera.position.x+Vx,
	Camera.position.y+Vy,
	Camera.position.z+Vz

	local mx,my,mlmb,_,mrmb,_=mouse()
	if mrmb then
		Camera.rotation.y=Camera.rotation.y-((Oldmx or mx)-mx)
		Camera.rotation.x=Camera.rotation.x-((Oldmy or my)-my)
	end
	Oldmx,Oldmy=mx,my

	Camera.position.x,Camera.position.y,Camera.position.z=
	math.max(-17,math.min(17,Camera.position.x)),
	math.max(floor,math.min(17,Camera.position.y)),
	math.max(-17,math.min(17,Camera.position.z))

	Camera.rotation.x=math.min(90,math.max(-90,Camera.rotation.x))

	if Gun and mlmb then
	if not Fired then

	local gx,gy,gz=Vector.rotate(1,-1.5,3,
		-math.rad(Camera.rotation.x),
		-math.rad(Camera.rotation.y),
		0)

		table.insert(Bullets,{
 position={
 x=Camera.position.x+gx,
 y=Camera.position.y+gy,
 z=Camera.position.z+gz},

 rotation={
 x=-Camera.rotation.x,
 y=-Camera.rotation.y,
 z=-Camera.rotation.z},
 scale={x=1,y=1,z=1},
 mesh=Meshes.sprite,
 size=false,
 })
	Fired=true
	end
	else Fired=false end

	Objects[1].rotation.y=Objects[1].rotation.y+1
	Objects[2].rotation.y=Objects[2].rotation.y+1
	Objects[3].rotation.y=Objects[3].rotation.y-1
	for i=4,6 do
		Objects[i].rotation.y=Objects[i].rotation.y+1
	end
	Objects[9].rotation.y=Objects[3].rotation.y-1
	Objects[10].text=T//20%2==0 and "!hello world!" or "hello world"
	Objects[10].color=T/5
	Objects[11].buttoncolor=1+ (T//10%2)

	local obj=Objects[8]
	if Gun then
		obj.position={x=1,y=-1.5,z=0}
		obj.rotation={x=0,y=0,z=0}
	else
		obj.position={x=0,y=3,z=0}
		obj.rotation.x=-30
		obj.rotation.y=obj.rotation.y+2
	end
		obj.lock_to_camera=Gun

	for _,b in pairs(Bullets) do
		local vx,vy,vz=Vector.rotate(0,0,1,
		 math.rad(b.rotation.x),
		 math.rad(b.rotation.y),
		 0)

		b.position.x,b.position.y,b.position.z=
		b.position.x+vx,
		b.position.y+vy,
		b.position.z+vz
	end

end



-- <TILES>
-- 002:000000000000000c0000000c0000000c0000000c0000000c0000000c0000000c
-- 003:00000000cccccccc33003cc233003cc233003cc233003cc003330cc0cccccccc
-- 004:00000000ccccc0002022c0002222c0002222c0002220c0000200c000ccccc000
-- 018:ccccccccc66660ccc66006ccc66006ccc66660ccc66006cccccccccc0000000c
-- 019:ccccccccdddddccadd000ccadddd0ccadd000ccadd000ccacccccccccccccc00
-- 020:cccccccca000cc22a000cc22a000cc22a000cc22aaaacc22cccccccc00000000
-- 021:cccc0000220c0000002c0000220c0000002c0000220c0000cccc000000000000
-- 034:0000000c0000000c0000000c0000000c0000000c0000000c0000000000000000
-- 035:44440c0044004c0044004c0044004c0044440c00cccccc000000000000000000
-- 048:aaaaaaaaaaaaaaaaacccccccacc0ccc0acc0ccc0acc0ccc0acccccccaaaaaaaa
-- 049:aaa00000aaa00000cca00000cca00000cca00000cca00000cca00000aaa00000
-- 064:aaacaaacaaaacccaaaaaaaaaaaaaaaaa00000000000000000000000000000000
-- 065:aaa00000aaa00000aaa00000aaa0000000000000000000000000000000000000
-- 080:6565656556565656656565655656565665656565565656566565656556565656
-- 096:eeeeee00eeeeee00eeddee00eeeeee00eeeeee00eeeeeee0e22e22e0eeeeeee0
-- 255:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

