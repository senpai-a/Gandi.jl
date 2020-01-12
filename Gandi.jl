module Valkyrie

export moveTo,click,drag,dragTo,mouseDown,mouseUp
export position,findPattern,locate
export screenSize,pyautogui
export waitToSee,waitToClick

using PyCall
using Images
#using FFTW
using Statistics
using ImageFeatures

const pyautogui = pyimport("pyautogui")
const numpy = pyimport("numpy")
const image=pyimport("PIL.Image")
const screenSize = pyautogui.size()

"""
    see: get screen image
    range: (x(col), y(row), width(ncol), height(nrow))
"""
function see(range=(1,1,screenSize...))
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
function findPattern(scene::Array{<:Any,2},patt::Array{<:Any,2})
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

function findPattern(patt::String;range=(1,1,screenSize...))
    scene = see(range)
    findPattern(scene,Gray.(load(patt)))
end

"""
    locate: locate pattern in scene, return vector of matched location.
    using a FFT based cross-correlation scheme, can't deal with scaled/rotated pattern
"""
function locate(scene::Array{<:Any,2},patt::Array{<:Any,2};confidence=.9)
    m,n=size(scene)
    pm,pn=size(patt)
    scene = permutedims(channelview(RGB.(scene)),[2,3,1])
    patt = permutedims(channelview(RGB.(patt)),[2,3,1])
    scene_py = image.fromarray(reinterpret(UInt8,scene))
    patt_py = image.fromarray(reinterpret(UInt8,patt))
    ans = collect(pyautogui.locateAll(patt_py,scene_py,confidence=confidence))
    ans = sort((t->(t[2]+t[4]÷2,t[1]+t[3]÷2)).(ans))
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

function locate(patt::String;confidence=.9,range=(1,1,screenSize...))
    scene = see(range)
    locate(scene,load(patt);confidence=confidence)
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

function waitToClick(patt::String,range=(0,0,screenSize...),delay=0.5)
    patt = load(patt)
    scene = see(range)
    loc = locate(scene,patt)
    while isempty(loc)
        sleep(delay)
        scene = see(range)
        loc = locate(scene,patt)
    end
    click(loc[1])
    return nothing
end

function waitToSee(patt::String,range=(0,0,screenSize...),delay=0.5)
    patt = load(patt)
    scene = see(range)
    loc = locate(scene,patt)
    while isempty(loc)
        sleep(delay)
        scene = see(range)
        loc = locate(scene,patt)
    end
    return loc
end


# drafts for testing
#cd("C:/Users/Administrator/OneDrive/Gandi.jl/img")
#s = (x->load("$(x).png")).(0:7)
#pat = load("pat6.png")
#locate(s[1],pat)
#res=(x->locate(x,pat;confidence=.8)).(s)
#markPoint(s[2],res[2][1])

end # module Valkyrie

module FGOUI

using Main.Valkyrie:screenSize
export setAnchor!,pos
export servantSkill,skillTarget,orderChange,masterSkill,card,hogu

anchor = (0,0,screenSize...)

function setAnchor!(x,y,w,h)
    anchor = (x,y,w,h)
end

"""
    pos(x,y): transfer ratio coordinate (x,y) to screen coordinate
    where x and y are in 0~1 and pos(x,y) in [0,w]×[0,h]
    this supports variable resolution, but anchor must be set properly with setAnchor! at first
"""
pos(x,y) = (anchor[1]+round(Int,x*anchor[3]),anchor[2]+round(Int,y*anchor[4]))

function servantSkill(servantId,skillId)
    if servantId∉1:3 || skillId∉1:3
        throw(ErrorException("servantSkill: index out of range"))
    end
    x0,y = (52/960,(465-32)/960)
    dx = 70/960
    dx_servant = 238/960
    x = x0+(servantId-1)*dx_servant+(skillId-1)*dx
    click(pos(x,y)...)
end

function skillTarget(servantId)
    if servantId∉1:3
        throw(ErrorException("skillTarget: index out of range"))
    end
    x0,y = (254/960,(359-32)/960)
    dx = 230
    x = x0+(servantId-1)*dx
    click(pos(x,y)...)
end

function orderChange(id1,id2)
    if servantId∉1:6 || skillId∉1:6
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
    x,y = x0+(hoguId-1)*dx
    click(pos(x,y)...)
end

end #module FGOUI
