function Renderer.simpleClipScene(customscene)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump
	local drawdump=scene.drawdump

	if vertexdump.clippedverts==nil then vertexdump.clippedverts={} end
	local clippedverts=vertexdump.clippedverts

	local verts_behind={nil,nil}

	for eid=#drawdump,1,-1 do
		local element=drawdump[eid]
		local NofVerts=element.nofverts

		if NofVerts==3 then
			if not (element[1].z>0 or element[2].z>0 or element[3].z>0) then table.remove(drawdump,eid)
			elseif element[1].z<0 or element[2].z<0 or element[3].z<0 then

			local verts_behind_len=0

				for i=1,3 do; if element[i].z<0 then
					verts_behind[verts_behind_len+1]=i verts_behind_len=verts_behind_len+1
				end; end

				if verts_behind_len==1 then
					local v1,v2,v3=element[verts_behind[1]],

					element[((verts_behind[1]-2)%3)+1],
					element[((verts_behind[1])%3)+1]


					local new_vert=RendererLib.UV3DLerp(v1,v2,nil,nil,nil,nil,v1.z/(v1.z-v2.z),nil,0.001)

					clippedverts[#clippedverts+1]=new_vert

					element[verts_behind[1]]=RendererLib.UV3DLerp(v1,v3,nil,nil,nil,nil,v1.z/(v1.z-v3.z),nil,0.001)

					clippedverts[#clippedverts+1]=element[verts_behind[1]]

					drawdump[#drawdump+1]={element[verts_behind[1]],v2,new_vert;  type="t",nofverts=3,data=element.data,uv=element.uv,object=element.object}

				else
					local v1,v2,v3=
					element[verts_behind[1]],element[verts_behind[2]],

					((verts_behind[1]%3)+1==verts_behind[2] and
					element[((verts_behind[1]-2)%3)+1]) or
					element[((verts_behind[1])%3)+1]


					element[verts_behind[1]]=RendererLib.UV3DLerp(v1,v3,nil,nil,nil,nil,v1.z/(v1.z-v3.z),nil,0.001)

					clippedverts[#clippedverts+1]=element[verts_behind[1]]

					element[verts_behind[2]]=RendererLib.UV3DLerp(v2,v3,nil,nil,nil,nil,v2.z/(v2.z-v3.z),nil,0.001)

					clippedverts[#clippedverts+1]=element[verts_behind[2]]
				end

			end

		elseif NofVerts==2 then
			table.remove(drawdump,eid)
		else
			if element[1].z<0 then table.remove(drawdump,eid) end
		end

	end
end
