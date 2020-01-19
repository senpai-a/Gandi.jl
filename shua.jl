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

function 女武神3T(target3=1)
    function f()
        #round 1
        #阵容：女武神 cba 孔明 | cba 加成 加成
        servantSkill(3,2)#孔明
        servantSkill(3,3)
        servantSkill(3,1;targetFriend=1)#孔明
        masterSkill(3;chOrder=(3,4))#换孔明->cba
        #阵容：女武神 cba cba | 孔明 加成 加成
        servantSkill(2,1;targetFriend=1)#cba
        servantSkill(3,1;targetFriend=1)#cba
        #女武神
        for i in 1:3
            servantSkill(1,i)
        end
        planCard([1],[1])#宝具id,宝具出牌顺序

        #round 2
        servantSkill(2,3;targetFriend=1)
        planCard([1],[1])

        #round 3
        masterSkill(1)#全体加攻
        masterSkill(2;targetEnemy=target3)#眩晕
        servantSkill(3,2)#cba
        servantSkill(2,2)
        servantSkill(3,3;targetFriend=1)
        planCard([1],[1])
    end
    return f
end

function 炼钢()
    #round 1
    #阵容：狂兰 cba stella | cba 羁绊
    servantSkill(3,3)
    planCard([3],[1])
    #round 2
    #阵容：狂兰 cba cba | 羁绊
    servantSkill(3,3;targetFriend=1)
    servantSkill(3,1;targetFriend=1)
    servantSkill(2,1;targetFriend=1)
    servantSkill(1,3)
    planCard([1],[1])
    #round 3
    masterSkill(2;targetFriend=1)#幻想强化
    servantSkill(2,3;targetFriend=1)
    servantSkill(2,2);servantSkill(3,2)
    planCard([1],[1])
end

#设置画面位置、分辨率
setAnchor!(3,33,960,540)

钢=[掉落计数("patt/blueshit.png","极光钢",33)]
for i in 1:66
    刷本(炼钢,"patt/free1.png","patt/friend1.png";
        吃苹果=true,
        掉落=钢,
        退出=退出(:刷满所有))
    log("已刷 $i 遍")
end
