local function PythSort(triA,triB)
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
end

local function PainterSort(triA,triB)
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
end

function Renderer.sortScene(customscene, SimpleSort)
	local scene=customscene or Renderer.data.scene
	local drawdump=scene.drawdump
	if SimpleSort==nil then SimpleSort=Renderer.defaultSettings.SimpleSort end

		local sortfunction
		if SimpleSort then
			sortfunction=PainterSort
		else
			sortfunction=PythSort
		end
		table.sort(drawdump,sortfunction)

end
