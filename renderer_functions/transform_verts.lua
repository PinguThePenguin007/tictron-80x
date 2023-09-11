function Renderer.transformVerts(customscene,customcam, CountVerts)

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
		 object_scale.x or object_scale[1] or 1,
		 object_scale.y or object_scale[2] or 1,
		 object_scale.z or object_scale[3] or 1
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

end
