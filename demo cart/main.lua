-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

package.path = "/home/pingu/tic80-folder/tictron-80x/?.lua"

require "demo cart/project_files/meshes"

require "renderer"

-- miscellanous libs
require "demo cart/project_files/libraries"

-- functions to help measure the time spent rendering
require "demo cart/project_files/marklib"

-- objects for rendering
Objects={

 tics={
 {
 position={x=0,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale=2,--scale can be defined as a single number
 mesh=Meshes.tic,
 originoffset={x=-3,y=0,z=0},--originoffset is helpful for changing the point of rotation of the object
 },
 {
 position={x=0,y=3,z=0},
 rotation={x=0,y=180,z=0},
 scale=2,
 mesh=Meshes.tic,
 originoffset={x=-3,y=0,z=0},
 }
 },

 heart={
 position={0,10,0}, --position and rotation can be defined as an array
 rotation={x=0,y=0,z=0},
 scale=1,
 mesh=Meshes.heart,
 },

 cubes={
 {
 position={x=30,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale=2,
 mesh=Meshes.cube,
 },
 {
 position={x=-30,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale=2,
 mesh=Meshes.cube,
 },
 {
 position={x=0,y=3,z=-30},
 rotation={x=0,y=0,z=0},
 scale=2,
 mesh=Meshes.cube,
 }
 },

 arena={
 position={x=0,y=0,z=0},
 rotation={x=0,y=0,z=0},
 scale={x=1,y=2,z=1},
 mesh=Meshes.arena,
 },
 circles={
 position={x=0,y=3,z=0},
 rotation={x=0,y=0,z=0},
 scale=7,
 mesh=Meshes.square,
 },
 text={
 position={x=0,y=7,z=0},
 rotation={x=0,y=0,z=0},
 scale=7,
 mesh=Meshes.text,
 color=0 --labels can be put right in the object's table
 },
 terminal={
 position={x=-17,y=0,z=17},
 rotation={x=0,y=0,z=0},
 scale=1,
 mesh=Meshes.terminal,
 buttoncolor=2,
 },

}

-- TODO: make a function to manipulate meshes
-- calculate the "sizes" of all the objects
for _,mesh in pairs(Meshes) do; if mesh.size==nil then
	local size=0
	for _,vert in pairs(mesh.verts) do
		size=math.max(size, Vector.GetLen(vert) )
	end
	mesh.size=size
end; end


Bullets={}
Targets={
{RenderObject=true, --affects addObjectsToScene(), addSingleObject() will still add an object with this value set to false
 position={x=0,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale=2,
 mesh=Meshes.tic,
},
{RenderObject=nil, -- nil will have the same effect as true
 position={x=-10,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale=2,
 mesh=Meshes.tic,
},
{RenderObject=true,
 position={x=10,y=3,z=40},
 rotation={x=0,y=-90,z=0},
 scale=2,
 mesh=Meshes.tic,
},
}

-- better keep objects in simple, shallow tables for faster access
ObjectList={Objects,Bullets,Targets,
Blaster={
 RenderObject=nil,
 position={x=0,y=3,z=0},
 rotation={x=30,y=0,z=0},
 scale=1,
 mesh=Meshes.blaster,
}
}

Rscene.camera={
position={x=0,y=3,z=-5},
rotation={x=0,y=0,z=0},
FOV=120,
CPlane=Renderer.CuttingPlanes.NearOnly
}

GuiObjects={
Gui_axis={
 position={x=0,y=0,z=1},
 rotation=Rscene.camera.rotation,
 scale=.1,
 mesh=Meshes.axis,
 lock_to_camera=true,
 rev_rot_order=true, -- the rotation order will be ZYX instead of XYZ
},
GuiBlaster={
 RenderObject=nil,
 position={x=1,y=-1.5,z=0},
 rotation={x=0,y=0,z=0},
 scale=1,
 mesh=Meshes.blaster,
 lock_to_camera=true -- while in this mode, position and rotation defines the object's offset
}
}

Blaster_active=true
NoClip=false

function TIC()
	T=(T and T+1) or 0

Zoffset=0

	Markinit()
	TotalTime=time()

	Renderer.resetScene()
	Gui_Scene={}
	Renderer.resetScene(Gui_Scene,Rscene.camera)

	Renderer.addObjectsToScene(ObjectList)

	Renderer.addObjectsToScene(GuiObjects,Gui_Scene)

	Renderer.clipObjects()

	local totalvertices=
	Renderer.transformVerts()
	+
	Renderer.transformVerts(Gui_Scene)

	Mark("VertDumpTime")

	Renderer.addDrawElements()
	Renderer.addDrawElements(Gui_Scene)

	Renderer.replaceLabels()
	Renderer.replaceLabels(Gui_Scene)
	Mark("TriDumpTime")

-- uncomment to enable display of object origins and their "sizes"
-- TODO: make a function to add debug objects to a scene
--[[
	for _,origin in pairs(Rscene.objectorigins) do
		Rscene.drawdump[#Rscene.drawdump+1]={
		 origin[1]; nofverts=1,type="c",
		 data={p=1,b=true,c=12,s=origin[1].radius},object=origin.object
		}
		end
	Renderer.projectVerts({vertexdump=Rscene.objectorigins,camera=Rscene.camera})
--]]

	Renderer.clipScene()
	Renderer.clipScene(Gui_Scene)
	Mark("TriClipTime")

	Renderer.sortScene()
	Renderer.sortScene(Gui_Scene)
	Mark("TriSortTime")


	-- huge thanks to Mypka_Max and soxfox42 for finding out this trick

	vbank(1);cls()

	--draw the scene to be dithered
	Renderer.buildColorMap(254)
	Renderer.drawScene()

	--overlay with lines to create a checker pattern
	for i=1,188 do line(i*2-136,0,i*2,136, 0) end


	vbank(0)

	cls(11)
--draw the scene
	Renderer.buildColorMap(255)
	Renderer.drawScene()

	--copy vbank(1) to vbank(0), overlaying our scene
	ttri(0,0,240,0,0,136,0,0,240,0,0,136,2,0)
	ttri(240,0,240,136,0,136,240,0,240,136,0,136,2,0)

	--clear vbank(1) for possible use later
	vbank(1);cls()

	vbank(0)

	--continue drawing

	Renderer.drawScene(Gui_Scene)

	Mark("TriDrawTime")

	local mem=collectgarbage("count")

--[[
Renderer.fullDraw({})
Renderer.fullDraw({},Gui_Scene)
--]]
	TotalTime=time()-TotalTime



	print("vertexes:"..totalvertices.."\ntris:"..#Renderer.data.scene.drawdump
	,1,1,15,false,1,true)

	if Markstr==nil or T%30==1 then

		Markstr=
		  "memory: "..mem*1000//1/1000 .."K\n"
		.."load:"..math.floor((TotalTime/(1000/60) )*100).."%\n"
		.."total: "..TotalTime*1000//1/1000 .."ms."

		Markstr2,M2Len=Markprint(function(name,value) return
		name..": "..value*1000//1/1000 .."ms." end,true)

	end
	print(Markstr,1,13,15,false,1,true)
	print(Markstr2,240-M2Len,1,15,false,1,true)

	Markclear()

	-- player controller

	local camera=Rscene.camera

	local Vx,Vz=0,0
	Vy=(not NoClip and Vy) and Vy-.02  or 0

	local floor=3

	local speed=.2
	local jumpspeed=.6
	if key(23) or btn(0) then Vz= speed end
	if key(19) or btn(1) then Vz=-speed end
	if key(1)  or btn(2) then Vx=-speed end
	if key(4)  or btn(3) then Vx= speed end

	if (key(48) or btn(4)) and (NoClip or camera.position.y<=floor) then Vy=NoClip and speed or jumpspeed end
	if key(64) and NoClip then Vy=-speed end




	Vx,_,Vz=Vector.rotate(Vx,0,Vz,
		0,-math.rad(camera.rotation.y),0)

	camera.position.x,camera.position.y,camera.position.z=
	camera.position.x+Vx,
	camera.position.y+Vy,
	camera.position.z+Vz

	local mx,my,mlmb,_,mrmb,_=mouse()
	if mrmb then
		camera.rotation.y=camera.rotation.y-((Oldmx or mx)-mx)
		camera.rotation.x=camera.rotation.x-((Oldmy or my)-my)
	end
	Oldmx,Oldmy=mx,my

	--limit position (who even needs collision algorithms?)
	if not NoClip then
		camera.position.x,camera.position.y,camera.position.z=
		math.max(  -17,math.min(17,camera.position.x)),
		math.max(floor,math.min(17,camera.position.y)),
		math.max(  -17,math.min(17,camera.position.z))
	end

	if btnp(5) then NoClip=not NoClip Blaster_active=not NoClip end

	--limit camera rotation
	camera.rotation.x=math.min(90,math.max(-90,camera.rotation.x))

--blaster controller

	if Blaster_active and mlmb then
	if not Fired then

		local gx,gy,gz=Vector.rotate(1,-1.5,3,
			-math.rad(camera.rotation.x),
			-math.rad(camera.rotation.y),
			0)

		table.insert(Bullets,{
		 position={
		 x=camera.position.x+gx,
		 y=camera.position.y+gy,
		 z=camera.position.z+gz},

		 rotation={
		 x=-camera.rotation.x,
		 y=-camera.rotation.y,
		 z=-camera.rotation.z},
		 scale=1,
		 mesh=Meshes.sprite,
		})
		Fired=true
	end
	else Fired=false end

	--object animation

	for _,tic in pairs(Objects.tics) do
		tic.rotation.y=tic.rotation.y+1
	end
	for _,cube in pairs(Objects.cubes) do
		cube.rotation.y=cube.rotation.y+1
	end
	Objects.heart.rotation.y=Objects.heart.rotation.y-1
	Objects.circles.rotation.y=Objects.circles.rotation.y-1

	Objects.text.text=T//20%2==0 and "!hello world!" or "hello world" --comment me
	Objects.text.color=T/5
	Objects.terminal.buttoncolor=1+ (T//10%2)

	if not Blaster_active then
		ObjectList.Blaster.rotation.y=ObjectList.Blaster.rotation.y+2
	end
	ObjectList.Blaster.RenderObject=not Blaster_active
	GuiObjects.GuiBlaster.RenderObject= Blaster_active


		-- bullet controller

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
-- 254:1122334411223344556677885566778899aabbcc99aabbccddeeff00ddeeff00
-- 255:001122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- </TILES>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

