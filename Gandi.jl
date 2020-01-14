module Valkyrie

export moveTo,click,drag,dragTo,mouseDown,mouseUp
export position,findPattern,locate
export anchor,setAnchor!,pos
export waitToSee,waitToClick,tryToClick,isSeeing

using PyCall
using Images
#using FFTW
using Statistics
using ImageFeatures

const pyautogui = pyimport("pyautogui")
const numpy = pyimport("numpy")
const image=pyimport("PIL.Image")
global anchor = [1,1,pyautogui.size()...]

function setAnchor!(x,y,w,h)
    global anchor = [x,y,w,h]
end

"""
    pos(x,y): transfer ratio coordinate (x,y) to screen coordinate
    where x and y are in 0~1 and pos(x,y) in [0,w]×[0,h]
    this supports variable resolution, but anchor must be set properly with setAnchor! at first
"""
pos(x,y) = (anchor[1]+round(Int,x*anchor[3]),anchor[2]+round(Int,y*anchor[4]))

"""
    see: get screen image
    range: (x(col), y(row), width(ncol), height(nrow))
"""
function see(range=anchor)
    s = pyautogui.screenshot(region = (range[1]-1,range[2]-1,range[3],range[4]))
    ns = numpy.array(s)
    ret = permutedims(reinterpret(N0f8,ns),[3,1,2])
    colorview(RGB,ret)
end

moveTo(x,y) = pyautogui.moveTo(x,y)
click(x,y) = pyautogui.click(x=x,y=y)
click() = pyautogui.click()
dragTo(x,y;button="left") = pyautogui.dragTo(x,y;button=button)
drag(x,y;button="left") = pyautogui.drag(x,y;button=button)
mouseDown(button="left") = pyautogui.mouseDown(button=button)
mouseUp(button="left") = pyautogui.mouseUp(button=button)
position() = pyautogui.position()

"""
    findPattern: find pattern in scene. if fail, returns (-1,-1), otherwise returns position of the pattern
    using a keypoint matching scheme
    if the pattern appears multiple times it will also fail (cuz my algorithm too stupid)
        TODO: handle multiple pattern senatio (for small scaling and rotation, use a clustering method)
"""
function findPattern(scene::AbstractArray{<:Any,2},patt::AbstractArray{<:Any,2})
    gscene = Gray.(scene)
    gpatt = Gray.(patt)
    freak = FREAK()
    kps = Keypoints(fastcorners(gscene, 12, 0.35))
    kpp = Keypoints(fastcorners(gpatt, 12, 0.35))
    desc_1, ret_keypoints_1 = create_descriptor(gscene, kps, freak)
    desc_2, ret_keypoints_2 = create_descriptor(gpatt, kpp, freak)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2,.18)
    shifts = (x->Tuple(x[1]).-Tuple(x[2])).(matches)
    nmatch = length(matches)
    shifts = hcat(collect.(shifts)...)
    cent = median(shifts,dims=2)
    out = 0
    dthreshold = 5
    # check failure, this also rejects when multiple pattern shows up
    for i in 1:nmatch
        d = sum(abs2,(shifts[:,i].-cent))
        if d>dthreshold^2 out+=1 end
    end
    if out>nmatch/3 || nmatch <= 3
        return (-1,-1)
    else
        return Tuple(Int.(cent).+size(patt).÷2)
        #Tuple(Int.(cent))
    end
end

function findPattern(patt::String;range=anchor)
    scene = see(range)
    findPattern(scene,Gray.(load(patt)))
end

"""
    locate: locate pattern in scene, return vector of matched location.
    using a FFT based cross-correlation scheme, can't deal with scaled/rotated pattern
"""
function locate(scene::AbstractArray{<:Any,2},patt::AbstractArray{<:Any,2};confidence=.9)
    m,n=size(scene)
    pm,pn=size(patt)
    scene = permutedims(channelview(RGB.(scene)),[2,3,1])
    patt = permutedims(channelview(RGB.(patt)),[2,3,1])
    scene_py = image.fromarray(reinterpret(UInt8,scene))
    patt_py = image.fromarray(reinterpret(UInt8,patt))
    ans = collect(pyautogui.locateAll(patt_py,scene_py,confidence=confidence))
    ans = sort((t->(t[1]+pn÷2,t[2]+pm÷2)).(ans))
    if length(ans)<2 return ans end

    #clustering ans
    dd = min(pm,pn)/2
    ret = Tuple{Int,Int}[]
    check = 1
    while !isempty(ans)
        push!(ret,ans[1])
        popfirst!(ans)
        for i in length(ans):-1:1
            if sum(abs2,ans[i].-ret[check])<dd^2
                deleteat!(ans,i)
            end
        end
        check+=1
    end
    ret
end

function locate(patt::String;confidence=.9,range=anchor)
    scene = see(range)
    offset = Tuple(range[1:2])
    (x->x.+offset).(locate(scene,load(patt);confidence=confidence))
end

function markPoint(img,pos)
    y = pos[2]
    x = pos[1]
    ret = img
    m,n=size(img)
    t = max(x-3,1)
    b = min(x+3,m)
    l = max(y-3,1)
    r = min(y+3,n)
    ret[t:b,l:r].=RGB(1,0,0)
    ret
end

function waitToClick(patt::String,range=anchor,delay=0.5)
    sleep(delay)
    patt = load(patt)
    scene = see(range)
    offset = Tuple(range[1:2])
    loc = (x->x.+offset).(locate(scene,patt))
    while isempty(loc)
        sleep(delay)
        scene = see(range)
        loc = (x->x.+offset).(locate(scene,patt))
    end
    click(loc[1]...)
    return nothing
end

function waitToSee(patt::String,range=anchor,delay=0.3)
    sleep(delay)
    patt = load(patt)
    scene = see(range)
    offset = Tuple(range[1:2])
    loc = (x->x.+offset).(locate(scene,patt))
    while isempty(loc)
        sleep(delay)
        scene = see(range)
        loc = (x->x.+offset).(locate(scene,patt))
    end
    sleep(delay)
    return loc
end

function tryToClick(patt::String,range=anchor)::Bool
    loc = locate(patt;range=range)
    if isempty(loc) return false
    else
        click(loc[1]...)
        return true
    end
end

function isSeeing(patt::String,range=anchor)::Bool
    !isempty(locate(patt;range=range))
end

end # module Valkyrie

module FGOUI

using Main.Valkyrie
export servantSkill,skillTarget,orderChange,masterSkill,card,hogu
export selectEnemy,cardSelection,quitCardSelection
export selectApple,refreshFriend,selectFriend
export servantSkillSync,masterSkillSync

function selectApple()
    click(pos(762/960,393/540)...)
    x,y = (490/960,367/540)
    dy = -110/540
    for i in 0:2
        sleep(0.1)
        click(pos(x,y+i*dy)...)
    end
    sleep(0.2)
    click(pos(626/960,420/540)...)
end

function refreshFriend()
    click(pos(640/960,96/540)...)
    sleep(0.2)
    click(pos(545/960,420/540)...)
end

function selectFriend(patt::String;refreshRate=10)
    tried = 0
    while tryToClick(patt,anchor)==false
        log("refresh friend list")
        refreshFriend()
        sleep(refreshRate)
        tried+=1
        if tried>10
            throw(ErrorException("selectFriend: failed, check friend list."))
        end
    end
end

function selectEnemy(id)
    if id∉1:3
        throw(ErrorException("selectEnemy: index out of range"))
    end
    x0,y = (31/960,30/540)
    dx = 180/960
    x = x0+(id-1)*dx
    click(pos(x,y)...)

    sleep(.3)
    if isSeeing("patt/enemyDoubleSelect.png")
        waitToClick("patt/enemyDoubleSelect.png")
    end
    sleep(.3)
end

function servantSkill(servantId,skillId)
    if servantId∉1:3 || skillId∉1:3
        throw(ErrorException("servantSkill: index out of range"))
    end
    x0,y = (52/960,(465-32)/540)
    dx = 70/960
    dx_servant = 238/960
    x = x0+(servantId-1)*dx_servant+(skillId-1)*dx
    click(pos(x,y)...)
end

function servantSkillSync(servantId,skillId;targetFriend=0,targetEnemy=0)
    if servantId∉1:3 || skillId∉1:3 || targetFriend∉0:3 || targetEnemy∉0:3
        throw(ErrorException("servantSkillSync: index out of range"))
    end
    if targetEnemy!=0
        selectEnemy(targetEnemy)
    end
    servantSkill(servantId,skillId)
    if targetFriend!=0
        sleep(.4)
        skillTarget(targetFriend)
    end
    waitToSee("patt/rdy.png")
end

function skillTarget(servantId)
    if servantId∉1:3
        throw(ErrorException("skillTarget: index out of range"))
    end
    x0,y = (254/960,(359-32)/540)
    dx = 230/960
    x = x0+(servantId-1)*dx
    click(pos(x,y)...)
end

function orderChange(id1,id2)
    if id1∉1:6 || id2∉1:6
        throw(ErrorException("orderChange: index out of range"))
    end
    x0,y = (100/960,260/540)
    dx = 150/960
    x1 = x0+(id1-1)*dx
    x2 = x0+(id2-1)*dx
    click(pos(x1,y)...); sleep(.2)
    click(pos(x2,y)...); sleep(.2)
    click(pos(480/960,470/540)...)
end

function masterSkill(skillId)
    if skillId∉1:3
        throw(ErrorException("masterSkill: index out of range"))
    end
    click(pos(897/960,235/540)...); sleep(.2)
    x0,y = (680/960,235/540)
    dx = 65/960
    x = x0 + (skillId-1)*dx
    click(pos(x,y)...)
end

function masterSkillSync(skillId;targetFriend=0,targetEnemy=0,chOrder=(0,0))
    if skillId∉1:3 || targetFriend∉0:3 || targetEnemy∉0:3 ||
        chOrder[1]∉0:6 || chOrder[2]∉0:6
        throw(ErrorException("masterSkillSync: index out of range"))
    end
    if targetEnemy!=0
        selectEnemy(targetEnemy)
    end
    masterSkill(skillId)
    if targetFriend!=0
        sleep(.4)
        skillTarget(targetFriend)
    elseif chOrder!=(0,0)
        orderChange(chOrder...)
    end
    waitToSee("patt/rdy.png")
end

function card(cardId)
    if cardId∉1:5
        throw(ErrorException("card: index out of range"))
    end
    x0,y = (96/960,382/540)
    dx = 192/960
    x = x0 + (cardId-1)*dx
    click(pos(x,y)...)
end

function hogu(hoguId)
    if hoguId∉1:3
        throw(ErrorException("hogu: index out of range"))
    end
    x0,y = (307/960,152/540)
    dx = 170/960
    x = x0+(hoguId-1)*dx
    click(pos(x,y)...)
end

function cardSelection()
    click(pos(855/960,455/540)...)
    sleep(2.5)
end

function quitCardSelection()
    click(pos(900/960,510/540)...)
end

end # module FGOUI

module FGO

using Main.Valkyrie
using Main.FGOUI
using Dates
export planCard,enterQuest,瞎几把打
export 刷本
export log

import Base.log
function log(msg::String)
    f = open("log.txt","a")
    msg = "$(now()): $msg"
    println(f,msg)
    println(msg)
    close(f)
end

function planCard(hoguId=Int[],hoguOrd=Int[])
    if length(hoguId)!=length(hoguOrd) || length(hoguId)>3
        throw(ErrorException("planCard: invalid hogu arguments."))
    end
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
    #println("priority: $que")
    selected = falses(5)
    cardQue = Int[]
    for cardi in que
        selected[cardi]=true
        push!(cardQue,cardi)
    end
    for i in 1:5
        if !selected[i] push!(cardQue,i) end
    end
    #println("cardQue: $cardQue")
    cardi = 1
    for i in 1:5
        if i in hoguOrd
            hogui = indexin(i,hoguOrd)[1]
            hogu(hoguId[hogui])
            #println("hogu: $(hoguId[hogui])")
        else
            card(cardQue[cardi])
            #println("card: $(cardQue[cardi])")
            cardi+=1
        end
    end
    return nothing
end

function 瞎几把打()
    log("开始瞎几把打")
    nextRound = isSeeing("patt/rdy.png")
    endQ = isSeeing("patt/end1.png")
    while !nextRound && !endQ
        log("等等看是继续打还是打完了")
        sleep(3)
        nextRound = isSeeing("patt/rdy.png")
        endQ = isSeeing("patt/end1.png")
    end
    log("继续打=$(nextRound) 打完了=$(endQ)")
    while nextRound && !endQ
        log("继续打")
        cardSelection();sleep(2)
        hogu(1); planCard()
        nextRound = isSeeing("patt/rdy.png")
        endQ = isSeeing("patt/end1.png")
        while !nextRound && !endQ
            log("等等看是继续打还是打完了")
            sleep(3)
            nextRound = isSeeing("patt/rdy.png")
            endQ = isSeeing("patt/end1.png")
        end
    end
    log("打完了")
    waitToClick("patt/end1.png")
    click();sleep(0.2)
    waitToClick("patt/end2.png")
    click();sleep(0.2)
    waitToClick("patt/end3.png")
    sleep(2)
    if isSeeing("patt/end4.png")
        waitToClick("patt/end4.png")
    end
    log("出来了")
end

function enterQuest(entryPatt::String="patt/questEntry.png")
    log("Quest start.")
    waitToClick(entryPatt)
    sleep(2)
    if isSeeing("patt/appleG.png")
        selectApple()
    end
    sleep(4)
    selectFriend("patt/friend.png")
    sleep(.5)
    waitToClick("patt/start.png")
end

function 刷本(套路::Function,本::String="patt/questEntry.png")
    enterQuest(本)
    套路()
    瞎几把打()#finish up
end

end  # module FGO
