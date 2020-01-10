module Valkyrie

export moveTo,click,drag,dragTo,mouseDown,mouseUp
export position,findPattern
export screenSize,pyautogui

using PyCall
using Images
using FFTW
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
    find pattern in scene. if fails return (-1,-1), otherwise returns position of the pattern
    if the pattern appears multiple times it will also fail (cuz my algorithm too stupid)
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
    x = pos[2]
    y = pos[1]
    ret = img
    m,n=size(img)
    t = max(y-3,1)
    b = min(y+3,m)
    l = max(x-3,1)
    r = min(x+3,n)
    ret[t:b,l:r].=RGB(1,0,0)
    ret
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

using Main.Valkyrie


end #module FGOUI
