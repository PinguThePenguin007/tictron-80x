function Renderer.replaceLabels(customscene)

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
		-- finally, we overwrite the element's data
		element.data=new_element_data

	end
end
