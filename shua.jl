cd("C:/Users/Alex Yu/OneDrive/Gandi.jl")
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

function quest()
    log("Quest start.")

    waitToClick("patt/questEntry.png")
    sleep(2)
    if isSeeing("patt/appleG.png")
        selectApple()
    end
    sleep(1)
    selectFriend("patt/friend.png")
    sleep(.5)
    waitToClick("patt/start.png")

    #round 1
    waitToSee("patt/rdy.png")
    servantSkill(3,2);sleep(3)#孔明
    servantSkill(3,3);sleep(3)

    servantSkill(2,1);sleep(.4)#cba
    skillTarget(1);sleep(3)

    cardSelection();sleep(2)
    hogu(1); card(1); card(2)

    #round 2
    waitToSee("patt/rdy.png")
    servantSkill(3,1);sleep(.4)#孔明
    skillTarget(1);sleep(3)
    masterSkill(3);sleep(.4)
    orderChange(3,4);sleep(5)

    servantSkill(3,1);sleep(.4)#cba
    skillTarget(1);sleep(3)
    servantSkill(3,3);sleep(.4)#cba
    skillTarget(1);sleep(3)

    servantSkill(1,3);sleep(3)
    cardSelection();sleep(2)
    hogu(1); card(1); card(2)

    #round 3
    waitToSee("patt/rdy.png")
    servantSkill(3,2);sleep(3)
    servantSkill(2,2);sleep(3)
    servantSkill(2,3);sleep(.4)#cba
    skillTarget(1);sleep(3)
    cardSelection();sleep(2)
    hogu(1); card(1); card(2)
end

setAnchor!(3,33,960,540)
quest()
