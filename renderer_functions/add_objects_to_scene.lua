function Renderer.addObjectsToScene(list,customscene,depth,AddOrigins)

	depth=depth or 5

	if type(list)=="table" and list.RenderObject~=false and list.RenderTable~=false then

		if list.RenderObject~=nil or list.mesh~=nil then
			Renderer.addSingleObject(list,customscene,AddOrigins)
		else
			for _,sublist in pairs(list) do
				if depth>0 then Renderer.addObjectsToScene(sublist,customscene,depth-1,AddOrigins) end
			end
		end

	end

end
