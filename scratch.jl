push!(LOAD_PATH, pwd())
using Revise

import Cube
x = Cube.MagicCube(3)
for c in x
    println(c)
end
