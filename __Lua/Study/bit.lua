
ik = {-1,"cc","dd"}

ik[0] = "dddd"

print(ik[0])
print("num" .. #ik)
for i,v in pairs(ik) do
print(i,v) 
end
---------------------------------------------------------------------------------3---------------------------------------------------------------
print("---------------------------------4------------------------------")



require "bit"
a = {1,2,3,x=5,cb =nil}

function SetIndex(index)
   a.x = index
   function GetIndex()
      return a.x
   end
end
---------------------------------------------------------------------------------3---------------------------------------------------------------
print("---------------------------------3------------------------------")
m = 1
n = 0
r1= bit.bor(m,n) --与
r2= bit.band(m,n)--或
r3= bit.bxor(m,n)--非
print(r1,r2,r3)



--------------------------------------------------------------------------------2-----------------------------------------------------------------
print("---------------------------------2------------------------------")
a.cb = SetIndex
a.cb(88)

--print(GetIndex())


local num = bit.tobit(0x08040201)
--print(num)
local a1 = 1
local al1= bit.lshift(a1,1)
local al2= bit.lshift(a1,2)
print(al2)



---------------------------------1------------------------------
--[[
print(a.x)
SetIndex(99)
print(GetIndex())--]]