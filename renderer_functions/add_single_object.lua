function Renderer.addSingleObject(object,customscene, AddOrigins)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump

	AddOrigins=AddOrigins or AddOrigins==nil

	if AddOrigins then
		scene.objectorigins=scene.objectorigins or {}
	end
	local objectorigins=scene.objectorigins

	local NofLists=#vertexdump+1

	local object_scale=object.scale or 1
	local scalex,scaley,scalez
	if type(object_scale)=="table" then
	 scalex,scaley,scalez=
	 object_scale.x or object_scale[1] or 1,
	 object_scale.y or object_scale[2] or 1,
	 object_scale.z or object_scale[3] or 1
	else scalex,scaley,scalez=object_scale,object_scale,object_scale end

	vertexdump[NofLists]={object=object}

	if AddOrigins then
		local maxscale=math.max(math.abs(scalex),math.abs(scaley),math.abs(scalez))

		local objsize
		if object.size~=nil then objsize=object.size
		else objsize=object.mesh.size; end

		if objsize~=false then
			objectorigins[NofLists]={object=object,{x=0,y=0,z=0,radius=(objsize or 1)*maxscale}}
		end
	end

	local list=vertexdump[NofLists]

	for vid,vertex in pairs(object.mesh.verts) do
		list[vid]={x=vertex.x,y=vertex.y,z=vertex.z}
	end


end
