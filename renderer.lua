
-- The small library used by the Renderer, I recommend leaving it alone unless you know what you're doing
RendererLib={

--[[
Rotates a 3D vector by applying X,Y,Z rotations individually.
The rotation order can be changed to Z,Y,X respectively.

Not actually used in the Renderer, but useful nevertheless!
]]
rotate=function(vx,vy,vz,rotx,roty,rotz,reverseOrder)

-- local variables are accessed faster
	local sin,cos=math.sin,math.cos

-- precalculated sin and cos because they are used multiple times in the formulas
	local sin_rotx,cos_rotx,sin_roty,cos_roty,sin_rotz,cos_rotz=
	sin(rotx),cos(rotx),
	sin(roty),cos(roty),
	sin(rotz),cos(rotz)

--[[
the actual formula, much like the 2D rotation one but applied three times for different axis

the way order changes may be a bit messy, but I think it's the best performance-wise
]]
	if reverseOrder then
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
	end
-- X axis
		vy,vz=
			vy* cos_rotx+vz* sin_rotx,
			vy*-sin_rotx+vz* cos_rotx
	if not reverseOrder then
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
	end

	return vx,vy,vz
end,

--[[
Rotates a 3D vector, but doesn't calculate sin and cos of the rotation degrees, so they can be precalculated outside. Really improves performance!

Is the actual rotation function being used in the Renderer.
]]
rotatePreCalc=function(vx,vy,vz,sin_rotx,cos_rotx,sin_roty,cos_roty,sin_rotz,cos_rotz,reverseOrder)

	if reverseOrder then
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
	end
-- X axis
		vy,vz=
		 vy* cos_rotx+vz* sin_rotx,
		 vy*-sin_rotx+vz* cos_rotx
	if not reverseOrder then
-- Y axis
		vx,vz=
		 vx* cos_roty+vz*-sin_roty,
		 vx* sin_roty+vz* cos_roty
-- Z axis
		vx,vy=
		 vx* cos_rotz+vy* sin_rotz,
		 vx*-sin_rotz+vy* cos_rotz
	end

	return vx,vy,vz
end,

--[[
Instead of accepting and outputting a {x,y,z} vector, those "Raw" functions simply input and output x,y,z
variables. Massively improves performance, because of the Lua quirks.
What the functions do is self-explanatory, i hope.
]]
GetDotRaw=function (ax,ay,az,bx,by,bz)
	return ax*bx+ay*by+az*bz
end,

-- Get the normal of a triangle using its 3 vertices
GetNormalRaw=function (ax,ay,az,bx,by,bz,cx,cy,cz)
	local va_x,va_y,va_z=ax-bx,ay-by,az-bz
	local vb_x,vb_y,vb_z=cx-bx,cy-by,cz-bz
	return
	 va_y*vb_z-va_z*vb_y,
	 va_z*vb_x-va_x*vb_z,
	 va_x*vb_y-va_y*vb_x
end,

NormalizeRaw=function(vx,vy,vz)
	local lenV=math.sqrt(vx*vx+vy*vy+vz*vz)
	return vx/lenV,vy/lenV,vz/lenV
end,

-- Linear interpolation of a 3D vector.
Lerp=function (a,b,n)
	return {x=a.x+(b.x-a.x)*n,
	        y=a.y+(b.y-a.y)*n,
	        z=a.z+(b.z-a.z)*n}
end,

-- Some of the functions were originally taken from the works of nequ16, and modified by me.
}

Renderer={

defaultSettings={

-- Whether to display the back face of triangles ("false") or not ("true").
-- Improves performance if set to "true".
BackfaceCulling=true,

-- If disabled, gives more accurate results, at cost of performance.
SimpleSort=true,

-- Option to use tri for untextured triangles (if set to "false").
-- Not recommended to disable, although performance is better this way.
UseTTriOnly=true,

-- Draws a wireframe for triangles.
Wireframe=false,


EnableLabels=true,
ClipObjects=true,
Sort=true,

CountVerts=true,
},

-- the Renderer's data, which is (usually) used during processing.
data={

scene={

-- contains vertices for transformation and other uses
vertexdump={
clippedverts={}, --contains vertices resulted from clipping the scene
},

-- contains draw elements (triangles, lines, etc.) for drawing, sorting, etc.
drawdump={},

},

-- if the UseTTriOnly setting is enabled, this map is used for proper coloring
colorToUVMap={},

},

-- Debug variables.
debug={

vertexcount=0 --does what it says on the tin

},

-- The default cutting planes for clipping the scene.
CuttingPlanes={

NearOnly={}, --for clipping directly in front of the camera (usually the fastest)
NearFar={}, --for clipping in the front, both close and at a distance (recommended)
Full={} --for full clipping, both near, far, and at all the sides (usually the slowest)

},

-- Resets the default scene and setups some other variables for the Renderer, if need be.
-- Should be reset at least 1 time during program execution befofe doing anything else!
resetScene=function(customcam)
	local camera=customcam or Camera --camera data is used to recalculate CPlanes only

	-- we clear our working tables and out vertex count
	Renderer.data.scene={vertexdump={ clippedverts={} }, drawdump={}}

	Renderer.debug.vertexcount=0

	-- we create our plane and map data if they were not created yet, so you have less work to do
	if #Renderer.CuttingPlanes==0 then Renderer.recalculateCPlanes(camera) end
	if #Renderer.data.colorToUVMap==0  then Renderer.buildColorMap(255) end

end,

-- Returns an empty custom scene to work with.
customScene=function()
	return {vertexdump={clippedverts={}},drawdump={}}
end,

-- Builds a color map based on a special sprite where each color corresponds to
-- UV coordinates of the color on the sprite.
buildColorMap=function(sprite)

	local colorToUVMap={} --prepare a table
	for color=0,15 do --do for each color:
		--transform a sprite's ID to its starting coordinates and add an offset based on the color
		local u,v=
		 (sprite%16)*8+(color%4)*2+1,
		 (sprite//16)*8+(color//4)*2+1
		colorToUVMap[color]={u,v,u,v,u,v} --add that to the table
	end

	Renderer.data.colorToUVMap=colorToUVMap --apply to global table
end,

recalculateCPlanes=function(customcam)
	local camera=customcam or Camera or {}

	local camFOV=camera.FOV or 120


	local NearPlane={position={x=0,y=0,z=camera.NearDistance or .1},normal={x=0,y=0,z=1}}
	local FarPlane={position={x=0,y=0,z=camera.FarDistance or 64},normal={x=0,y=0,z=-1}}
	local UpPlane={position={x=0,y=0,z=0},normal={x=0,y=1,z=68/camFOV}}
	local DownPlane={position={x=0,y=0,z=0},normal={x=0,y=-1,z=68/camFOV}}
	local LeftPlane={position={x=0,y=0,z=0},normal={x=-1,y=0,z=120/camFOV}}
	local RightPlane={position={x=0,y=0,z=0},normal={x=1,y=0,z=120/camFOV}}



	Renderer.CuttingPlanes.NearOnly[1]=NearPlane

	Renderer.CuttingPlanes.NearFar[1]=NearPlane
	Renderer.CuttingPlanes.NearFar[2]=FarPlane

	Renderer.CuttingPlanes.Full[1]=NearPlane
	Renderer.CuttingPlanes.Full[2]=FarPlane
	Renderer.CuttingPlanes.Full[3]=UpPlane
	Renderer.CuttingPlanes.Full[4]=DownPlane
	Renderer.CuttingPlanes.Full[5]=LeftPlane
	Renderer.CuttingPlanes.Full[6]=RightPlane

end,

addObjectsToScene=function(objects,customscene, AddOrigins)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump

	AddOrigins=AddOrigins or AddOrigins==nil

	if AddOrigins then
		scene.objectorigins=scene.objectorigins or {}
	end
	local objectorigins=scene.objectorigins

	local NofLists=#vertexdump
	for oid,object in pairs(objects) do

		local object_scale=object.scale
		local scalex,scaley,scalez
		if type(object_scale)=="table" then
		 scalex,scaley,scalez=
		 object_scale.x or object_scale[1] or 0,
		 object_scale.y or object_scale[2] or 0,
		 object_scale.z or object_scale[3] or 0
		else scalex,scaley,scalez=object_scale,object_scale,object_scale end

		vertexdump[oid+NofLists]={object=object}

		if AddOrigins then
			local maxscale=math.max(math.abs(scalex),math.abs(scaley),math.abs(scalez))

			local objsize
			if object.size~=nil then objsize=object.size
			else objsize=object.mesh.size; end

			if objsize~=false then
				objectorigins[oid+NofLists]={object=object,{x=0,y=0,z=0,radius=(objsize or 1)*maxscale}}
			end
		end

		local list=vertexdump[oid+NofLists]

		for vid,vertex in pairs(object.mesh.verts) do
			list[vid]={x=vertex.x,y=vertex.y,z=vertex.z}
		end


	end


end,

clipObjects=function(customscene)

	local scene=customscene or Renderer.data.scene
	local objectorigins=scene.objectorigins
	local vertexdump=scene.vertexdump

	local NormalizeRaw,GetDotRaw=RendererLib.NormalizeRaw,RendererLib.GetDotRaw

	Renderer.transformVerts({vertexdump=objectorigins},nil,false)

	for _,cPlane in pairs(Renderer.CuttingPlanes.Full) do
		local cPlanePOSx,cPlanePOSy,cPlanePOSz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz=
		 cPlane.position.x,cPlane.position.y,cPlane.position.z,
		 cPlane.normal.x,cPlane.normal.y,cPlane.normal.z

		local normPx,normPy,normPz=
		 NormalizeRaw(cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

		for key,list in pairs(objectorigins) do; local P=list[1]

			local radius=P.radius
			local SubPx,SubPy,SubPz=
			 P.x-cPlanePOSx,P.y-cPlanePOSy,P.z-cPlanePOSz

			local radPx,radPy,radPz=
			 SubPx+(normPx*radius),
			 SubPy+(normPy*radius),
			 SubPz+(normPz*radius)

			local DotP=
			 GetDotRaw(radPx,radPy,radPz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

			if DotP<0 then
				vertexdump[key]=nil
			end

		end

	end
end,

transformVerts=function(customscene,customcam, CountVerts)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump

	local camera=customcam or Camera

	local vertcount=Renderer.debug.vertexcount
	if CountVerts==nil then CountVerts=Renderer.defaultSettings.CountVerts end

	local sin,cos=math.sin,math.cos
	local rotate=RendererLib.rotatePreCalc

	local CAMrotx,CAMroty,CAMrotz=
	 math.rad(camera.rotation.x or camera.rotation[1] or 0),
	 math.rad(camera.rotation.y or camera.rotation[2] or 0),
	 math.rad(camera.rotation.z or camera.rotation[3] or 0)

	local CAMposx,CAMposy,CAMposz=
	 camera.position.x or camera.position[1] or 0,
	 camera.position.y or camera.position[2] or 0,
	 camera.position.z or camera.position[3] or 0

	local CAMoffsetx,CAMoffsety,CAMoffsetz
		if camera.originoffset then
			CAMoffsetx,CAMoffsety,CAMoffsetz=
			 camera.originoffset.x or camera.originoffset[1] or 0,
			 camera.originoffset.y or camera.originoffset[2] or 0,
			 camera.originoffset.z or camera.originoffset[3] or 0
		else CAMoffsetx,CAMoffsety,CAMoffsetz=0,0,0 end

	local
	sin_CAMrotx,cos_CAMrotx,
	sin_CAMroty,cos_CAMroty,
	sin_CAMrotz,cos_CAMrotz=
	 sin(CAMrotx),cos(CAMrotx),
	 sin(CAMroty),cos(CAMroty),
	 sin(CAMrotz),cos(CAMrotz)




	for lkey,list in pairs(vertexdump) do if lkey~="clippedverts" then
	local object=list.object

		local OBJrotx,OBJroty,OBJrotz=
		 math.rad(object.rotation.x or object.rotation[1] or 0),
		 math.rad(object.rotation.y or object.rotation[2] or 0),
		 math.rad(object.rotation.z or object.rotation[3] or 0)


		local OBJposx,OBJposy,OBJposz=
		 object.position.x or object.position[1] or 0,
		 object.position.y or object.position[2] or 0,
		 object.position.z or object.position[3] or 0

		local object_scale=object.scale
		local scalex,scaley,scalez
		if type(object_scale)=="table" then
		 scalex,scaley,scalez=
		 object_scale.x or object_scale[1] or 0,
		 object_scale.y or object_scale[2] or 0,
		 object_scale.z or object_scale[3] or 0
		else scalex,scaley,scalez=object_scale,object_scale,object_scale end

		local OBJoffsetx,OBJoffsety,OBJoffsetz
		if object.originoffset then
			OBJoffsetx,OBJoffsety,OBJoffsetz=
			 object.originoffset.x or object.originoffset[1] or 0,
			 object.originoffset.y or object.originoffset[2] or 0,
			 object.originoffset.z or object.originoffset[3] or 0
		else OBJoffsetx,OBJoffsety,OBJoffsetz=0,0,0 end

		local
		sin_OBJrotx,cos_OBJrotx,
		sin_OBJroty,cos_OBJroty,
		sin_OBJrotz,cos_OBJrotz=
			sin(OBJrotx),cos(OBJrotx),
			sin(OBJroty),cos(OBJroty),
			sin(OBJrotz),cos(OBJrotz)



		local lock_to_camera=object.lock_to_camera
		local rev_rot_order=object.rev_rot_order

		for vkey,vertex in pairs(list) do if vkey~="object" then
			local vertx,verty,vertz=
			  vertex.x+OBJoffsetx,
			  vertex.y+OBJoffsety,
			  vertex.z+OBJoffsetz

			vertx,verty,vertz=
			 vertx*scalex,
			 verty*scaley,
			 vertz*scalez

			vertx,verty,vertz=rotate(vertx,verty,vertz,
			 sin_OBJrotx,cos_OBJrotx,
			 sin_OBJroty,cos_OBJroty,
			 sin_OBJrotz,cos_OBJrotz,rev_rot_order)

			vertx,verty,vertz=
			 vertx+OBJposx,
			 verty+OBJposy,
			 vertz+OBJposz

			if not lock_to_camera then
				vertx,verty,vertz=
				 vertx-CAMposx,
				 verty-CAMposy,
				 vertz-CAMposz

				vertx,verty,vertz=rotate(vertx,verty,vertz,
				 sin_CAMrotx,cos_CAMrotx,
				 sin_CAMroty,cos_CAMroty,
				 sin_CAMrotz,cos_CAMrotz,true)

				vertx,verty,vertz=
				 vertx-CAMoffsetx,
				 verty-CAMoffsety,
				 vertz-CAMoffsetz
			end

			vertex.x,vertex.y,vertex.z=vertx,verty,vertz

		if CountVerts then vertcount=vertcount+1 end

		end end
	end end
	Renderer.debug.vertexcount=vertcount

end,

addDrawElements=function(customscene, BackfaceCulling)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump
	local vertexdump=scene.vertexdump

	if BackfaceCulling==nil then BackfaceCulling=Renderer.defaultSettings.BackfaceCulling end
	local nobackfaceculling=not BackfaceCulling

	local GetDotRaw,GetNormalRaw=RendererLib.GetDotRaw,RendererLib.GetNormalRaw

	for key,vertlist in pairs(vertexdump) do if key~="clippedverts" then local object=vertlist.object

		for etype,drawelement in pairs(object.mesh.drawdata) do
			local IsTrisOnly= type(etype)=="number"

			if IsTrisOnly or etype=="t" then
				local tritable
				if IsTrisOnly then tritable=object.mesh.drawdata
				else tritable=drawelement end

				for _,triangle in pairs(tritable) do
					local p1,p2,p3,normal=
					 vertlist[ triangle.p[1] ],
					 vertlist[ triangle.p[2] ],
					 vertlist[ triangle.p[3] ],
					 (triangle.n or 1)

					if not (p1==nil or p2==nil or p3==nil) then

						if nobackfaceculling or normal==2 or normal==((
							GetDotRaw(
								p1.x,p1.y,p1.z,
								GetNormalRaw(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z,p3.x,p3.y,p3.z)
							)>0) and 0 or 1)
						then
							drawdump[#drawdump+1]={p1,p2,p3; nofverts=3,type="t",
							 data=triangle,uv=triangle.uv,object=object}
						end
					end

				end

			if IsTrisOnly then break end

			elseif etype=="l" then

				for _,line in pairs(drawelement) do
					local p1,p2=vertlist[line.p[1]],vertlist[line.p[2]]
					if not (p1==nil or p2==nil) then
						drawdump[#drawdump+1]={p1,p2; nofverts=2,type="l",
						 data=line,object=object}
					end
				end

			else

				for _,dot in pairs(drawelement) do
					local p1=vertlist[dot.p]
					if p1~=nil then
						drawdump[#drawdump+1]={p1; nofverts=1,type=etype,
						 data=dot,object=object}
					end
				end

			end
		end
	end end

end,

replaceLabels=function(customscene)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump

	for _,element in pairs(drawdump) do
		-- local variables are accessed faster
		local element_object=element.object
		-- also, we protect ourselves from trying to look into a table that might not exist
		local meshlabels=element_object.mesh.labels or {}

		-- we create a new table to then fill it with entries from the old data table
		local new_element_data={p=element.data.p; }
		for entry,data in pairs(element.data) do
			-- we don't want to mess with the vertex data
			if entry~="p" then
				--[[ we first check for labels per-object, then we check for them in the mesh data, and then
				we assign the data to the new entry correspondingly]]
				if      element_object[data]~=nil then new_element_data[entry]=element_object[data]
				 elseif meshlabels[data]    ~=nil then new_element_data[entry]=meshlabels[data]
				 elseif data                ~=nil then new_element_data[entry]=data
				end

			end
		end
		-- finally, we overwrite the element's data'
		element.data=new_element_data

	end
end,

clipScene=function(customscene, customcam)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump
	local drawdump=scene.drawdump

	local camera=customcam or Camera

	local clippedverts=vertexdump.clippedverts

	local GetDotRaw,lerp=RendererLib.GetDotRaw,RendererLib.Lerp

	for _,cPlane in pairs(camera.CPlane) do
		local cPlanePOSx,cPlanePOSy,cPlanePOSz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz=
		 cPlane.position.x,cPlane.position.y,cPlane.position.z,
		 cPlane.normal.x,cPlane.normal.y,cPlane.normal.z

		for eid=#drawdump,1,-1 do
			local element=drawdump[eid]
			local NofVerts=element.nofverts

		if NofVerts==3 then

			local P1,P2,P3=element[1],element[2],element[3]
			local SubP1x,SubP2x,SubP3x,SubP1y,SubP2y,SubP3y,SubP1z,SubP2z,SubP3z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,P3.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,P3.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz,P3.z-cPlanePOSz
			local DotP={
			 GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP3x,SubP3y,SubP3z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)
			}

			local d=DotP


			if d[1]<0 and d[2]<0 and d[3]<0 then
				table.remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 or d[3]<0 then

				local out={}

				local v=element
				local hasuv=not (element.data.uv==nil)

				local uv
				if hasuv then local element_uv=element.uv
					uv={{x=element_uv[1],y=element_uv[2],z=0},
			        {x=element_uv[3],y=element_uv[4],z=0},
			        {x=element_uv[5],y=element_uv[6],z=0}}
			end

				for i=1,3 do
					if d[i]>=0 and d[i%3+1]>=0 then
						local newuv
						if hasuv then newuv=uv[i] end

						out[#out+1]={p=v[i],uv=newuv}
					end
					if d[i]>=0 and d[i%3+1]<0 then
						local vSlide=d[i]/(d[i]-d[i%3+1])
						local newuv,newuv2
						if hasuv then newuv=uv[i]
							newuv2=lerp(uv[i],uv[i%3+1],vSlide)
						end

						out[#out+1]={p=v[i],uv=newuv}

						local p=lerp(v[i],v[i%3+1],vSlide)
						out[#out+1]={
						 p=p,
						 uv=newuv2}
						 clippedverts[#clippedverts+1]=p
					end
					if d[i]<0 and d[i%3+1]>=0 then
						local vSlide=d[i]/(d[i]-d[i%3+1])
						local newuv
						if hasuv then
							newuv=lerp(uv[i],uv[i%3+1],vSlide)
						end

						local p=lerp(v[i],v[i%3+1],vSlide)
						out[#out+1]={
						 p=p,
						 uv=newuv}
						 clippedverts[#clippedverts+1]=p
					end
				end


				element[1]=out[1].p
				element[2]=out[2].p
				element[3]=out[3].p
				if hasuv then
				 element.uv={
				  out[1].uv.x,out[1].uv.y,out[2].uv.x,
				  out[2].uv.y,out[3].uv.x,out[3].uv.y} end
				if #out==4 then
					local uvlist
					if hasuv then uvlist={
					 out[1].uv.x,out[1].uv.y,out[3].uv.x,
					 out[3].uv.y,out[4].uv.x,out[4].uv.y}
					end
				 table.insert(drawdump,{out[1].p,out[3].p,out[4].p;  type="t",nofverts=3,data=element.data,uv=uvlist,object=element.object})
				end
			end
		elseif NofVerts==2 then

			local P1,P2=element[1],element[2]
			local SubP1x,SubP2x,SubP1y,SubP2y,SubP1z,SubP2z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz
			local DotP={
			 GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			 GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz),
			}

			local d=DotP

			if d[1]<0 and d[2]<0 then
				table.remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 then

					if d[1]<0 then
						P1=lerp(P1,P2,d[1]/(d[1]-d[2]))
						clippedverts[#clippedverts+1]=P1
					end
					if d[2]<0 then
						P2=lerp(P2,P1,d[2]/(d[2]-d[1]))
						clippedverts[#clippedverts+1]=P2
					end

					element[1],element[2]=P1,P2
			end
		else

			local P=element[1]
			local SubPx,SubPy,SubPz=
			 P.x-cPlanePOSx,P.y-cPlanePOSy,P.z-cPlanePOSz
			local DotP=
			 GetDotRaw(SubPx,SubPy,SubPz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)

			if DotP<0 then
				table.remove(drawdump,eid)
			end
		end
		end
	end


end,

sortScene=function(customscene, SimpleSort)
	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump
	if SimpleSort==nil then SimpleSort=Renderer.defaultSettings.SimpleSort end

	local PainterSort,PythSort=Renderer.PainterSort,Renderer.PythSort

		local sortfunction
		if SimpleSort then
			sortfunction=PainterSort
		else
			sortfunction=PythSort
		end
		table.sort(drawdump,sortfunction)

end,

PythSort=function(triA,triB)
	local avgXA,avgYA,avgZA=0,0,0
	if triA.nofverts==3 then
		local tri1,tri2,tri3=triA[1],triA[2],triA[3]
		avgXA,avgYA,avgZA=
		 (tri1.x+tri2.x+tri3.x)/3,
		 (tri1.y+tri2.y+tri3.y)/3,
		 (tri1.z+tri2.z+tri3.z)/3
	elseif triA.nofverts==2 then
		local tri1,tri2=triA[1],triA[2]
		avgXA,avgYA,avgZA=
		 (tri1.x+tri2.x)/2,
		 (tri1.y+tri2.y)/2,
		 (tri1.z+tri2.z)/2
	else local point=triA[1]
		avgXA,avgYA,avgZA=
		 point.x,
		 point.y,
		 point.z
	end

	local avgXB,avgYB,avgZB=0,0,0
	if triB.nofverts==3 then
		local tri1,tri2,tri3=triB[1],triB[2],triB[3]
		avgXB,avgYB,avgZB=
		 (tri1.x+tri2.x+tri3.x)/3,
		 (tri1.y+tri2.y+tri3.y)/3,
		 (tri1.z+tri2.z+tri3.z)/3
	elseif triB.nofverts==2 then
		local tri1,tri2=triB[1],triB[2]
		avgXA,avgYA,avgZA=
		 (tri1.x+tri2.x)/2,
		 (tri1.y+tri2.y)/2,
		 (tri1.z+tri2.z)/2
	else local point=triB[1]
		avgXB,avgYB,avgZB=
		 point.x,
		 point.y,
		 point.z
	end

	return (avgXA*avgXA)+(avgYA*avgYA)+(avgZA*avgZA) >
	       (avgXB*avgXB)+(avgYB*avgYB)+(avgZB*avgZB)
end,

PainterSort=function(triA,triB)
	local avgZA=0
	if triA.nofverts==3 then
		avgZA=(triA[1].z+triA[2].z+triA[3].z)/3
	elseif triA.nofverts==2 then
		avgZA=(triA[1].z+triA[2].z)/2
	else
		avgZA=triA[1].z
	end
	local avgZB=0
	if triB.nofverts==3 then
		avgZB=(triB[1].z+triB[2].z+triB[3].z)/3
	elseif triB.nofverts==2 then
		avgZB=(triB[1].z+triB[2].z)/2
	else
		avgZB=triB[1].z
	end

	return avgZA > avgZB
end,

projectVerts=function(customscene,customcam,CenterX,CenterY)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump

	local camera=customcam or Camera
	local CAMFOV=camera.FOV or 120
	local centerx,centery=CenterX or 120,CenterY or 68

	for _,list in pairs(vertexdump) do
		for key,vert in pairs(list) do if key~="object" then
			local vertz=vert.z
			if vertz~=0 then
				vert.drawx,vert.drawy=
				 (vert.x/vertz)*CAMFOV+centerx,
				 (-vert.y/vertz)*CAMFOV+centery
			else vert.drawx,vert.drawy=0,0 end
		end end
	end
end,

drawScene=function(customscene,project,customcam,CenterX,CenterY, UseTTriOnly,Wireframe)

	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump

	local colorToUVMap=Renderer.data.colorToUVMap
	if UseTTriOnly==nil then UseTTriOnly=Renderer.defaultSettings.UseTTriOnly end
	if Wireframe==nil then Wireframe=Renderer.defaultSettings.Wireframe end

	if project or project==nil then Renderer.projectVerts(scene,CenterX,CenterY,customcam) end

	local CAMFOV=Camera.FOV or 120

	local tri,ttri,trib,line,circ,circb,print=tri,ttri,trib,line,circ,circb,print

	for _,element in pairs(drawdump) do
		local element_data=element.data

		if not element_data.hidden then

			if element.type=="t" then
				local p1,p2,p3,color=
				 element[1],element[2],element[3],element_data.c

				local uvtri=element.uv or colorToUVMap[color%16]

				if UseTTriOnly or color==nil then
					ttri(p1.drawx,p1.drawy,
					     p2.drawx,p2.drawy,
					     p3.drawx,p3.drawy,
					     uvtri[1],uvtri[2],
					     uvtri[3],uvtri[4],
					     uvtri[5],uvtri[6],
					     false,-1,p1.z,p2.z,p3.z)
				else
					tri(p1.drawx,p1.drawy,
					    p2.drawx,p2.drawy,
					    p3.drawx,p3.drawy,color)
				end

				if Wireframe then
					trib(p1.drawx,p1.drawy,
					     p2.drawx,p2.drawy,
					     p3.drawx,p3.drawy,12)
				end

			elseif element.type=="c" then
				local p,size,color,circtype=element[1],element_data.s,

				element_data.c,

				(element_data.b and circb) or circ

				size=size/((p.z==0 and .1) or p.z)*CAMFOV

				circtype(p.drawx,p.drawy,size,color)

			elseif element.type=="txt" then

				local p,size,str,color,sf=element[1],
				element_data.s,
				element_data.str,
				element_data.c or 15,
				element_data.sf

				size=math.max(1,size/((p.z==0 and .1) or p.z)*CAMFOV)

				local strlen=print(str,1000,1000,nil,true,size,sf)/2

				print(str,p.drawx-strlen,p.drawy,color,true,size,sf)

			elseif element.type=="s" then
				local p,size,uv,t=element[1],element.data.s,element.data.uv,element.data.t

				size=(size/((p.z==0 and .1) or p.z)*CAMFOV)/2

				ttri(
				 p.drawx-size,p.drawy-size,
				 p.drawx+size,p.drawy-size,
				 p.drawx-size,p.drawy+size,
				 uv[1],uv[2],
				 uv[3],uv[2],
				 uv[1],uv[4],false,t)
				ttri(
				 p.drawx+size,p.drawy-size,
				 p.drawx-size,p.drawy+size,
				 p.drawx+size,p.drawy+size,
				 uv[3],uv[2],
				 uv[1],uv[4],
				 uv[3],uv[4],false,t)

			elseif element.type=="l" then

				local p1,p2,color=element[1],element[2],
				element_data.c

				line(
				 p1.drawx,p1.drawy,
				 p2.drawx,p2.drawy,color)

			end

		end
	end

end,

-- Does everything required to draw a scene, while still having customizability.
-- You still need to reset the scene yourself, though.
fullDraw=function(objects,customscene,settings,customcam,centerx,centery)

	settings=settings or {}
	if settings.ClipObjects==nil then settings.ClipObjects=Renderer.defaultSettings.ClipObjects end
	if settings.Sort==nil then settings.Sort=Renderer.defaultSettings.Sort end
	if settings.EnableLabels==nil then settings.EnableLabels=Renderer.defaultSettings.EnableLabels end


	Renderer.addObjectsToScene(objects,customscene, settings.clipObjects)
	if settings.ClipObjects then
		Renderer.clipObjects(customscene)
	end

	Renderer.transformVerts(customscene,customcam, settings.CountVerts)
	Renderer.addDrawElements(customscene, settings.BackfaceCulling)
	if settings.EnableLabels then
		Renderer.replaceLabels(customscene)
	end

	Renderer.clipScene(customscene,customcam)
	if settings.Sort then
		Renderer.sortScene(customscene, settings.SimpleSort)
	end

	Renderer.drawScene(customscene,true,centerx,centery,customcam, settings.UseTTriOnly, settings.Wireframe)

end,
}

