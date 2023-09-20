function Renderer.projectVerts(customscene,CenterX,CenterY,only_clippedverts)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump

	local camera=scene.camera
	local CAMFOV=camera.FOV or 120
	local centerx,centery=CenterX or 120,CenterY or 68


	for _,list in pairs(vertexdump) do
		if only_clippedverts then list=vertexdump.clippedverts end
		for key,vert in pairs(list) do; if key~="object" then
			local vertz=vert.z
			if vertz~=0 then
				vert.drawx,vert.drawy=
				 (vert.x/vertz)*CAMFOV+centerx,
				 (-vert.y/vertz)*CAMFOV+centery
			else vert.drawx,vert.drawy=0,0 end
		end end
		if only_clippedverts then break end
	end
end
