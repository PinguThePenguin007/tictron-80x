function Renderer.clipScene(customscene, customplanes)

	local scene=customscene or Renderer.data.scene
	local vertexdump=scene.vertexdump
	local drawdump=scene.drawdump

	local cplanes=customplanes or scene.camera.CPlane

	local clippedverts=vertexdump.clippedverts

	local GetDotRaw,uv3dlerp,table_remove,table_insert=RendererLib.GetDotRaw,RendererLib.UV3DLerp,table.remove,table.insert

	local d={true,true,true} --we can reuse a single table for multiple clipping operations

	for _,cPlane in pairs(cplanes) do
		local cPlanePOSx,cPlanePOSy,cPlanePOSz,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz=
		 cPlane.position.x,cPlane.position.y,cPlane.position.z,
		 cPlane.normal.x,cPlane.normal.y,cPlane.normal.z

		local plane_is_axis=(cPlanePOSx==cPlaneNORMx and cPlanePOSy==cPlaneNORMy) --check if the plane is perpendicular to the Z axis

		local direction,vert_POSz
		if plane_is_axis then -- ...the clipped vertex's Z coordinate will always be equal to the plane's Z position
		vert_POSz=cPlanePOSz --so, we don't need to calculate lerp of Z axis
		direction=cPlaneNORMz<0; end

		for eid=#drawdump,1,-1 do
			local element=drawdump[eid]
			local NofVerts=element.nofverts

			if plane_is_axis then
				local P1_GT_Plane,P2_GT_Plane,P3_GT_Plane=
				               element[1].z>cPlanePOSz,
				 NofVerts<2 or element[2].z>cPlanePOSz,
				 NofVerts<3 or element[3].z>cPlanePOSz

				if (P1_GT_Plane and P2_GT_Plane and P3_GT_Plane) ~= direction
				 then goto continue
				elseif ((not P1_GT_Plane) and (not P2_GT_Plane) and (not P3_GT_Plane)) ~= direction
				 then table_remove(drawdump,eid); goto continue
				end
			end



		if NofVerts==3 then

			local P1,P2,P3=element[1],element[2],element[3]
			local SubP1x,SubP2x,SubP3x,SubP1y,SubP2y,SubP3y,SubP1z,SubP2z,SubP3z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,P3.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,P3.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz,P3.z-cPlanePOSz

			d[1]=GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)
			d[2]=GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)
			d[3]=GetDotRaw(SubP3x,SubP3y,SubP3z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)





			if d[1]<0 and d[2]<0 and d[3]<0 then
				table_remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 or d[3]<0 then

				local out={}

				local v=element
				local hasuv=element.data.uv

				local uv
				if hasuv then uv=element.uv else uv={} end

				for i=1,3 do
					local nexti,uvindex= i%3+1, i*2
					if d[i]>=0 and d[nexti]>=0 then

						out[#out+1]={p=v[i],
						 uv_U=hasuv and uv[uvindex-1],
						 uv_V=hasuv and uv[uvindex]}

					end
					if d[i]>=0 and d[nexti]<0 then

						out[#out+1]={p=v[i],
						 uv_U=hasuv and uv[uvindex-1],
						 uv_V=hasuv and uv[uvindex]}

						local p,uv_u,uv_v=uv3dlerp(v[i],v[nexti],
						 uv[uvindex-1],uv[uvindex],
						 uv[nexti*2-1],uv[nexti*2],
						d[i]/(d[i]-d[nexti]),hasuv,vert_POSz)
						out[#out+1]={p=p,uv_U=uv_u,uv_V=uv_v}

						clippedverts[#clippedverts+1]=p

					end
					if d[i]<0 and d[nexti]>=0 then

						local p,uv_u,uv_v=uv3dlerp(v[i],v[nexti],
						 uv[uvindex-1],uv[uvindex],
						 uv[nexti*2-1],uv[nexti*2],
						d[i]/(d[i]-d[nexti]),hasuv,vert_POSz)

						out[#out+1]={p=p,uv_U=uv_u,uv_V=uv_v}

						clippedverts[#clippedverts+1]=p

					end
				end


				element[1]=out[1].p
				element[2]=out[2].p
				element[3]=out[3].p
				if hasuv then
				 element.uv={
				  out[1].uv_U,out[1].uv_V,out[2].uv_U,
				  out[2].uv_V,out[3].uv_U,out[3].uv_V} end
				if #out==4 then
					local uvlist
					if hasuv then uvlist={
					 out[1].uv_U,out[1].uv_V,out[3].uv_U,
					 out[3].uv_V,out[4].uv_U,out[4].uv_V}
					end
				 table_insert(drawdump,{out[1].p,out[3].p,out[4].p;  type="t",nofverts=3,data=element.data,uv=uvlist,object=element.object})
				end
			end

		elseif NofVerts==2 then

			local P1,P2=element[1],element[2]
			local SubP1x,SubP2x,SubP1y,SubP2y,SubP1z,SubP2z=
			 P1.x-cPlanePOSx,P2.x-cPlanePOSx,
			 P1.y-cPlanePOSy,P2.y-cPlanePOSy,
			 P1.z-cPlanePOSz,P2.z-cPlanePOSz

			d[1]=GetDotRaw(SubP1x,SubP1y,SubP1z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)
			d[2]=GetDotRaw(SubP2x,SubP2y,SubP2z,cPlaneNORMx,cPlaneNORMy,cPlaneNORMz)



			if d[1]<0 and d[2]<0 then
				table_remove(drawdump,eid)
			elseif d[1]<0 or d[2]<0 then

					if d[1]<0 then
						P1=uv3dlerp(P1,P2,nil,nil,nil,nil,d[1]/(d[1]-d[2]),nil,vert_POSz)
						clippedverts[#clippedverts+1]=P1
					end
					if d[2]<0 then
						P2=uv3dlerp(P2,P1,nil,nil,nil,nil,d[2]/(d[2]-d[1]),nil,vert_POSz)
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
				table_remove(drawdump,eid)
			end
		end

		::continue::
		end
	end


end
