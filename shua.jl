include("Gandi.jl")

using .Valkyrie
using .FGOUI
using Dates

import Base.log
function log(msg::String)
    f = open("log.txt","a")
    msg = "$(now()): $msg"
    println(f,msg)
    println(msg)
    close(f)
end

function planCard()
    priority = []
    for i in 1:9
        fn = "cardPlan/$(i).png"
        if isfile(fn)
            push!(priority,fn)
        end
    end
    que = []
    for pat in priority
        loc = locate(pat;range=FGOUI.anchor)
        append!(que,loc)
        if length(que)>=3 break end
    end
    #transform (x,y) to cardId
    a = FGOUI.anchor
    que = (x->((x[1]-a[1])/a[3],(x[2]-a[2])/a[4])).(que)
    que = (x->floor(Int,(x[1]-(38/960))*960/190+1)).(que)
    selected = falses(5)
    for cardi in que
        selected[cardi]=true
        card(cardi)
    end
    for i in 1:5
        if !selected[i] card(i) end
    end
end

function quest()
    log("Quest start.")
    waitToClick("patt/questEntry.png")
    sleep(2)
    if isSeeing("patt/appleG.png")
        selectApple()
    end
    sleep(2)
    selectFriend("patt/friend.png")
    sleep(.5)
    waitToClick("patt/start.png")

    #round 1
    waitToSee("patt/rdy.png")
    servantSkillSync(3,2)#孔明
    servantSkillSync(3,3)

    servantSkillSync(2,1;targetFriend=1)#cba

    cardSelection();sleep(2)
    hogu(1); planCard()

    #round 2
    waitToSee("patt/rdy.png")
    servantSkillSync(3,1;targetFriend=1)#孔明
    masterSkillSync(3;chOrder=(3,4))#换孔明->cba

    servantSkillSync(3,1;targetFriend=1)#cba
    servantSkillSync(3,3;targetFriend=1)

    servantSkillSync(1,3)#狂兰np率

    cardSelection();sleep(2)
    hogu(1); planCard()

    #round 3
    waitToSee("patt/rdy.png")
    masterSkillSync(1)
    masterSkillSync(2;targetEnemy=1)
    servantSkillSync(3,2)
    servantSkillSync(2,2)
    servantSkillSync(2,3;targetFriend=1)#cba

    servantSkillSync(1,1)#狂兰
    servantSkillSync(1,2)

    cardSelection();sleep(2)
    hogu(1); planCard()

    #round4 or end
    r4 = isSeeing("patt/rdy.png")
    endQ = isSeeing("patt/end1.png")
    while !r4 && !endQ
        log("wait for r4 or endQ")
        sleep(3)
        r4 = isSeeing("patt/rdy.png")
        endQ = isSeeing("patt/end1.png")
    end
    log("r4 or endQ, assume r4 xor endQ")
    log("r4=$(r4) endQ=$(endQ)")
    while r4 && !endQ
        log("in r4")
        cardSelection();sleep(2)
        hogu(1); planCard()
        r4 = isSeeing("patt/rdy.png")
        endQ = isSeeing("patt/end1.png")
        while !r4 && !endQ
            log("wait for r4 or endQ")
            sleep(3)
            r4 = isSeeing("patt/rdy.png")
            endQ = isSeeing("patt/end1.png")
        end
    end
    log("ended")
    waitToClick("patt/end1.png")
    click();click();sleep(0.2)
    waitToClick("patt/end2.png")
    click();click();sleep(0.2)
    waitToClick("patt/end3.png")
    sleep(2)
    if isSeeing("patt/end4.png")
        waitToClick("patt/end4.png")
    end
end

setAnchor!(3,33,960,540)
for i in 1:13
    quest()
end
