function Renderer.simpleClipScene(customscene)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump
	local drawdump=scene.drawdump

	local table_remove,uv3dlerp=table.remove,RendererLib.UV3DLerp

	if vertexdump.clippedverts==nil then vertexdump.clippedverts={} end
	local clippedverts=vertexdump.clippedverts

	local near_distance=.1

	local verts_behind={nil,nil}
	local verts_ahead={nil,nil}

	for eid=#drawdump,1,-1 do
		local element=drawdump[eid]
		local NofVerts=element.nofverts

		if NofVerts==3 then
			local element_1_z,element_2_z,element_3_z=element[1].z,element[2].z,element[3].z

			if not (element_1_z>near_distance or element_2_z>near_distance or element_3_z>near_distance) then
				table_remove(drawdump,eid)
			elseif element_1_z<near_distance or element_2_z<near_distance or element_3_z<near_distance then


				local hasuv=element.data.uv

				local uv
				if hasuv then uv=element.uv end


				local verts_behind_len,verts_ahead_len=0,0

				for i=1,3 do
					if element[i].z<near_distance then
						verts_behind[verts_behind_len+1]=i verts_behind_len=verts_behind_len+1
					else
						verts_ahead[verts_ahead_len+1]=i verts_ahead_len=verts_ahead_len+1
					end
				end


				if verts_behind_len==1 then
					local v1index,v2index,v3index=
					 verts_behind[1],

					 verts_ahead[1],
					 verts_ahead[2]

					local v1,v2,v3=
					 element[v1index],element[v2index],element[v3index]

					local v1indexM2,v2indexM2,v3indexM2=v1index*2,v2index*2,v3index*2
					local v1U_index,v1V_index,v2U_index,v2V_index,v3U_index,v3V_index=
					 v1indexM2-1,v1indexM2,
					 v2indexM2-1,v2indexM2,
					 v3indexM2-1,v3indexM2



					local new_vert,nvU,nvV=uv3dlerp(v1,v2,
					(v1.z-near_distance)/(v1.z-v2.z),near_distance,
					 hasuv,
					 hasuv and uv[v1U_index],
					 hasuv and uv[v1V_index],
					 hasuv and uv[v2U_index],
					 hasuv and uv[v2V_index])

					clippedverts[#clippedverts+1]=new_vert

					local v1U,v1V
					element[v1index],v1U,v1V=uv3dlerp(v1,v3,
					(v1.z-near_distance)/(v1.z-v3.z),near_distance,
					 hasuv,
					 hasuv and uv[v1U_index],
					 hasuv and uv[v1V_index],
					 hasuv and uv[v3U_index],
					 hasuv and uv[v3V_index])

					clippedverts[#clippedverts+1]=element[v1index]

					local newtri_uv
					if hasuv then
						local new_uv={nil,nil,nil,nil,nil,nil}

						new_uv[v1U_index]=v1U
						new_uv[v1V_index]=v1V
						new_uv[v2U_index]=uv[v2U_index]
						new_uv[v2V_index]=uv[v2V_index]
						new_uv[v3U_index]=uv[v3U_index]
						new_uv[v3V_index]=uv[v3V_index]

						element.uv=new_uv

						newtri_uv={
						 v1U,v1V,
						 uv[v2U_index],
						 uv[v2V_index],
						 nvU,nvV
						}

					end

					drawdump[#drawdump+1]={element[v1index],v2,new_vert;  type="t",nofverts=3,data=element.data,uv=newtri_uv,object=element.object}

				else
					local v1index,v2index,v3index=
					 verts_behind[1],
					 verts_behind[2],

					 verts_ahead[1]

					local v1,v2,v3=
					 element[v1index],element[v2index],element[v3index]

					local v1indexM2,v2indexM2,v3indexM2=v1index*2,v2index*2,v3index*2
					local v1U_index,v1V_index,v2U_index,v2V_index,v3U_index,v3V_index=
					 v1indexM2-1,v1indexM2,
					 v2indexM2-1,v2indexM2,
					 v3indexM2-1,v3indexM2



					local v1U,v1V
					element[v1index],v1U,v1V=uv3dlerp(v1,v3,
					(v1.z-near_distance)/(v1.z-v3.z),near_distance,
					 hasuv,
					 hasuv and uv[v1U_index],
					 hasuv and uv[v1V_index],
					 hasuv and uv[v3U_index],
					 hasuv and uv[v3V_index])

					clippedverts[#clippedverts+1]=element[v1index]

					local v2U,v2V
					element[v2index],v2U,v2V=uv3dlerp(v2,v3,
					(v2.z-near_distance)/(v2.z-v3.z),near_distance,
					 hasuv,
					 hasuv and uv[v2U_index],
					 hasuv and uv[v2V_index],
					 hasuv and uv[v3U_index],
					 hasuv and uv[v3V_index])

					clippedverts[#clippedverts+1]=element[v2index]

					if hasuv then
						local new_uv={nil,nil,nil,nil,nil,nil}

						new_uv[v1U_index]=v1U
						new_uv[v1V_index]=v1V
						new_uv[v2U_index]=v2U
						new_uv[v2V_index]=v2V
						new_uv[v3U_index]=uv[v3U_index]
						new_uv[v3V_index]=uv[v3V_index]

						element.uv=new_uv
					end

				end

			end

		elseif NofVerts==2 then

			local P1,P2=element[1],element[2]

			if P1.z<near_distance and P2.z<near_distance then
				table_remove(drawdump,eid)

			elseif P1.z<near_distance or P2.z<near_distance then

				if P1.z<near_distance then
					P1=uv3dlerp(P1,P2, (P1.z-near_distance)/(P1.z-P2.z),near_distance)
					clippedverts[#clippedverts+1]=P1
				else
					P2=uv3dlerp(P2,P1, (P2.z-near_distance)/(P2.z-P1.z),near_distance)
					clippedverts[#clippedverts+1]=P2
				end

					element[1],element[2]=P1,P2
			end

		else
			if element[1].z<near_distance then table_remove(drawdump,eid) end
		end

	end
end
