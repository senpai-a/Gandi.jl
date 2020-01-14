include("Gandi.jl")

using .Valkyrie
using .FGOUI
using .FGO

#编写你的策略为一个函数
function 狂兰孔明换人3T(target3=1)
    function f()
        #round 1
        #阵容：狂兰 cba 孔明 | cba 加成 加成
        servantSkill(3,2)#孔明
        servantSkill(3,3)
        servantSkill(2,1;targetFriend=1)#cba
        planCard([1],[1])#宝具id,宝具出牌顺序

        #round 2
        servantSkill(3,1;targetFriend=1)#孔明
        masterSkill(3;chOrder=(3,4))#换孔明->cba
        #阵容：狂兰 cba cba | 孔明 加成 加成
        servantSkill(3,1;targetFriend=1)#cba
        servantSkill(3,3;targetFriend=1)
        servantSkill(2,2)#cba
        servantSkill(1,3)#狂兰np率
        planCard([1],[1])

        #round 3
        masterSkill(1)#全体加攻
        masterSkill(2;targetEnemy=target3)#眩晕
        servantSkill(3,2)#cba
        servantSkill(2,3;targetFriend=1)
        servantSkill(1,1)#狂兰
        servantSkill(1,2)
        planCard([1],[1])
    end
    return f
end

#设置画面位置、分辨率
setAnchor!(3,33,960,540)
刷本(狂兰孔明换人3T(2),"patt/quest7.png")

#刷金材料本
for i in 1:ceil(Int,400/28)
    刷本(狂兰孔明换人3T(1),"patt/quest6.png")
end
#毛巾本
while true
    刷本(狂兰孔明换人3T(2),"patt/quest7.png")
end
