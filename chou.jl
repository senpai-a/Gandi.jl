include("Gandi.jl")

using .Valkyrie
using .FGOUI
using .FGO

#设置画面位置、分辨率
setAnchor!(3,33,960,540)

count = 0
while true
    reset = false
    while !reset
        for i in 1:100
            click(pos(320/960,340/540)...)
            sleep(.01)
        end
        if isSeeing("patt/endChou.png")
            println("Exiting")
            exit()
        end
        reset = isSeeing("patt/reset.png")
    end
	global count+=1
    println("$count 池")
    waitToClick("patt/reset.png")
    sleep(.5);click(pos(625/960,420/540)...)
    sleep(5);click(pos(480/960,420/540)...)
end
