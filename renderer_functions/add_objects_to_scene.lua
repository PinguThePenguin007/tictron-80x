function Renderer.addObjectsToScene(list,customscene,depth,AddOrigins)

	depth=depth or 5

	for key,sublist in pairs(list) do; if type(sublist)~="table" then return 0; else

		if sublist.RenderObject~=false and (sublist.RenderObject~=nil or sublist.mesh~=nil) then
			Renderer.addSingleObject(sublist,customscene,AddOrigins)
		else
			if depth>0 then Renderer.addObjectsToScene(sublist,customscene,AddOrigins,depth-1) end
		end

	end; end

end
