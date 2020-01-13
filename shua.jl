include("Gandi.jl")

using .Valkyrie
using .FGOUI
using .FGO

function 狂兰孔明换人3T(target1=1,target2=1,target3=1)
    function f()
        #round 1
        #阵容：狂兰 cba 孔明 | cba 加成 加成
        waitToSee("patt/rdy.png")#等待可以操作
        servantSkillSync(3,2)#孔明
        servantSkillSync(3,3)

        servantSkillSync(2,1;targetFriend=1)#cba

        selectEnemy(target1)
        cardSelection()#进入选卡
        planCard([1],[2])#宝具id,宝具出牌顺序

        #round 2
        waitToSee("patt/rdy.png")#等待可以操作
        servantSkillSync(3,1;targetFriend=1)#孔明
        masterSkillSync(3;chOrder=(3,4))#换孔明->cba
        #阵容：狂兰 cba cba | 孔明 加成 加成
        servantSkillSync(3,1;targetFriend=1)#cba
        servantSkillSync(3,3;targetFriend=1)

        servantSkillSync(1,3)#狂兰np率

        selectEnemy(target2)
        cardSelection()#进入选卡
        planCard([1],[2])#宝具id,宝具出牌顺序

        #round 3
        waitToSee("patt/rdy.png")#等待可以操作
        masterSkillSync(1)#全体加攻
        masterSkillSync(2;targetEnemy=target3)#眩晕
        servantSkillSync(3,2)#cba
        servantSkillSync(2,2)#cba
        servantSkillSync(2,3;targetFriend=1)

        servantSkillSync(1,1)#狂兰
        servantSkillSync(1,2)

        cardSelection()#进入选卡
        planCard([1],[1])
    end
    return f
end

setAnchor!(3,33,960,540)

#金材料
for i in 1:ceil(Int,(600+600+600+400+1000)/28)
    刷本(狂兰孔明换人3T(2,2,1),"patt/quest6.png")
end
