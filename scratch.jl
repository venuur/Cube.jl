push!(LOAD_PATH, pwd())
using Revise

import Cube
x = Cube.MagicCube(3)
for c in Cube.OneTurnNeighbors(x)
    println(c)
end

y = Cube.shuffle(x, 1)
