module Valkyrie

using PyCall
using Images
using FFTW
using Statistics
using ImageFeatures
const pyautogui = pyimport("pyautogui")
const numpy = pyimport("numpy")
const screenSize = pyautogui.size()

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
while true println(position()) end

function findPattern(scene::Array{<:Any,2},patt::Array{<:Any,2})
    gscene = Gray.(scene)
    gpatt = Gray.(patt)
    freak = FREAK()
    kps = Keypoints(fastcorners(gscene, 12, 0.35))
    kpp = Keypoints(fastcorners(gpatt, 12, 0.35))
    desc_1, ret_keypoints_1 = create_descriptor(gscene, kps, freak)
    desc_2, ret_keypoints_2 = create_descriptor(gpatt, kpp, freak)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2,.2)
    shifts = (x->Tuple(x[1]).-Tuple(x[2])).(matches)
    nmatch = length(matches)
    shifts = hcat(collect.(shifts)...)
    cent = median(shifts,dims=2)
    out = 0
    dthreshold = min(size(patt)...)/2
    for i in 1:nmatch
        d = sum(abs2,(shifts[:,i].-cent))
        if d>dthreshold^2 out+=1 end
    end
    if out>nmatch/3
        return (-1,-1)
    else
        return Tuple(Int.(cent).+size(patt).÷2)
        #Tuple(Int.(cent))
    end
end

function markPoint(img,pos)
    x = pos[2]
    y = pos[1]
    ret = img
    ret[y-3:y+3,x-3:x+3].=RGB(1,0,0)
    ret
end


# drafts for testing
cd("C:/Users/Administrator/OneDrive/Gandi.jl/img")
s = (x->load("$(x).png")).(0:7)
s[2]
pat = load("pat.png")
res=(x->findPattern(x,pat)).(s)
markPoint(s[1],res[1])
end # module Valkyrie
