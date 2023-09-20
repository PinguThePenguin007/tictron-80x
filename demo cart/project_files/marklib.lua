do
local marktable={}
local starttime=0

	function Markinit()
		starttime=time()
	end

	function Marktime(markname)
		for _,tbl  in pairs(marktable) do
			if tbl.name==markname then
				tbl.value=tbl.value+(time()-starttime)
				return nil
			end
		end
		marktable[#marktable+1]={name=markname,value=time()-starttime}
	end

	function Mark(markname)
		Marktime(markname)
		Markinit()
	end

	function Markprint(printstyle,smalltext)
	local str,strlen="",0
		for _,tbl  in pairs(marktable) do
			str=str..printstyle(tbl.name,tbl.value).."\n"
			strlen=math.max(strlen,print(printstyle(tbl.name,tbl.value),0,400,0,false,1,smalltext))
		end
		return str,strlen
	end

	function Markclear()
		marktable={}
	end
end
