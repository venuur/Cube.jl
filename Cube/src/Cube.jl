module Cube
# TODO:
#   0. Implement solved check for MagicCube.
#   1. Implement tree search from AI book on Kindle.  Although it will only probably find
#      the solution when the cube is not too shuffled due to run time.
#   2. Run simple benchmark for increasing shuffles n values to see how long simple searches
#      require to solve.
#

using DataStructures: Queue, enqueue!, dequeue!

import Base.iterate


"""
    MagicCube(n)

Return an n x n x n magic cube in solved state.

The only field is an array faces which stores the orientation of cube faces as an n x n x 6
array.  The last dimension indexes face with the following orientation:

Front:
```
  4
2 1 3 6
  5
```

Back:
```
  4
3 6 2 1
  5
```

"""
struct MagicCube
    faces::Array{Int, 3}
    n::Int
    MagicCube(n::Int) = new(reshape(hcat([fill(i, n, n) for i in 1:6]...), n, n, 6), n)
    MagicCube(m::MagicCube) = new(copy(m.faces), m.n)
end

# Front:
# ```
#   4
# 2 1 3 6
#   5
# ```
adjacent_faces(::Val{1}) = [2, 4, 3, 5]
adjacent_faces(::Val{2}) = [6, 4, 1, 5]
adjacent_faces(::Val{3}) = [1, 4, 6, 5]
adjacent_faces(::Val{4}) = [2, 6, 3, 1]
adjacent_faces(::Val{5}) = [2, 1, 3, 6]
adjacent_faces(::Val{6}) = [3, 4, 2, 5]

const opposite_face = [6, 3, 2, 5, 4, 1]

adjacent_rows(face::Val{1}, n::Int) = [n:-1:1, n, 1:n, 1]
adjacent_rows(face::Val{2}, n::Int) = [n:-1:1, 1:n, 1:n, 1:n]
adjacent_rows(face::Val{3}, n::Int) = [n:-1:1, n:-1:1, 1:n, n:-1:1]
adjacent_rows(face::Val{4}, n::Int) = [1, 1, 1, 1]
adjacent_rows(face::Val{5}, n::Int) = [n, n, n, n]
adjacent_rows(face::Val{6}, n::Int) = [n:-1:1, 1, 1:n, n]

adjacent_cols(face::Val{1}, n::Int) = [n, 1:n, 1, n:-1:1]
adjacent_cols(face::Val{2}, n::Int) = [n, 1, 1, 1]
adjacent_cols(face::Val{3}, n::Int) = [n, n, 1, n]
adjacent_cols(face::Val{4}, n::Int) = [n:-1:1, n:-1:1, n:-1:1, n:-1:1]
adjacent_cols(face::Val{5}, n::Int) = [1:n, 1:n, 1:n, 1:n]
adjacent_cols(face::Val{6}, n::Int) = [n, n:-1:1, 1, 1:n]

slice_rows(face::Val{1}, layer::Int, n::Int) = [n:-1:1, 1+n-layer, 1:n, layer]
slice_rows(face::Val{2}, layer::Int, n::Int) = [n:-1:1, 1:n, 1:n, 1:n]
slice_rows(face::Val{3}, layer::Int, n::Int) = [n:-1:1, n:-1:1, 1:n, n:-1:1]
slice_rows(face::Val{4}, layer::Int, n::Int) = [layer, layer, layer, layer]
slice_rows(face::Val{5}, layer::Int, n::Int) = [1+n-layer, 1+n-layer, 1+n-layer, 1+n-layer]
slice_rows(face::Val{6}, layer::Int, n::Int) = [n:-1:1, layer, 1:n, 1+n-layer]

slice_cols(face::Val{1}, layer::Int, n::Int) = [1+n-layer, 1:n, layer, n:-1:1]
slice_cols(face::Val{2}, layer::Int, n::Int) = [1+n-layer, layer, layer, layer]
slice_cols(face::Val{3}, layer::Int, n::Int) = [1+n-layer, 1+n-layer, layer, 1+n-layer]
slice_cols(face::Val{4}, layer::Int, n::Int) = [n:-1:1, n:-1:1, n:-1:1, n:-1:1]
slice_cols(face::Val{5}, layer::Int, n::Int) = [1:n, 1:n, 1:n, 1:n]
slice_cols(face::Val{6}, layer::Int, n::Int) = [1+n-layer, n:-1:1, layer, 1:n]

function adjacent_edge_values(cube::MagicCube, face::Int)
    faces = adjacent_faces(Val(face))
    rows = adjacent_rows(Val(face), cube.n)
    cols = adjacent_cols(Val(face), cube.n)
    hcat([cube.faces[r, c, f] for (r, c, f) in zip(rows, cols, faces)]...)
end

function adjacent_slice_values(cube::MagicCube, face::Int, layer::Int)
    faces = adjacent_faces(Val(face))
    rows = slice_rows(Val(face), layer, cube.n)
    cols = slice_cols(Val(face), layer, cube.n)
    hcat([cube.faces[r, c, f] for (r, c, f) in zip(rows, cols, faces)]...)
end

function face_clockwise!(cube::MagicCube, face::Int)
    face_values = @view cube.faces[:, :, face]
    edge_values = adjacent_edge_values(cube, face)

    # Rotate 90 degrees clockwise.
    af = adjacent_faces(Val(face))
    r = adjacent_rows(Val(face), cube.n)
    c = adjacent_cols(Val(face), cube.n)
    cube.faces[r[1], c[1], af[1]] = edge_values[:, 4]
    cube.faces[r[2], c[2], af[2]] = edge_values[:, 1]
    cube.faces[r[3], c[3], af[3]] = edge_values[:, 2]
    cube.faces[r[4], c[4], af[4]] = edge_values[:, 3]

    copyto!(face_values, rotr90(face_values))

    cube
end

function face_clockwise(cube::MagicCube, face::Int)
    newcube = MagicCube(cube)
    face_clockwise!(newcube, face)
end

function face_counterclockwise!(cube::MagicCube, face::Int)
    face_values = @view cube.faces[:, :, face]
    edge_values = adjacent_edge_values(cube, face)

    # Rotate 90 degrees counter-clockwise.
    af = adjacent_faces(Val(face))
    r = adjacent_rows(Val(face), cube.n)
    c = adjacent_cols(Val(face), cube.n)
    cube.faces[r[1], c[1], af[1]] = edge_values[:, 2]
    cube.faces[r[2], c[2], af[2]] = edge_values[:, 3]
    cube.faces[r[3], c[3], af[3]] = edge_values[:, 4]
    cube.faces[r[4], c[4], af[4]] = edge_values[:, 1]

    copyto!(face_values, rotl90(face_values))

    cube
end

function face_counterclockwise(cube::MagicCube, face::Int)
    newcube = MagicCube(cube)
    face_counterclockwise!(newcube, face)
end

"""
    slice_clockwise!(cube, face, layer)

Rotate ``layer`` of cube clockwise, where face determines the orientation to index layers.
For a ``MagicCube(n)``, layer 1 is the same as ``rotate_clockwise!(cube, face)`` and
layer ``n`` is the same as ``rotate_counterclockwise!(cube, opposite_face[face])``.

"""
function slice_clockwise!(cube::MagicCube, face::Int, layer::Int)
    if layer == 1
        return face_clockwise!(cube, face)
    elseif layer == cube.n
        return face_counterclockwise!(cube, opposite_face[face])
    end

    slice_values = adjacent_slice_values(cube, face, layer)

    # Rotate 90 degrees counter-clockwise.
    af = adjacent_faces(Val(face))
    r = slice_rows(Val(face), layer, cube.n)
    c = slice_cols(Val(face), layer, cube.n)
    cube.faces[r[1], c[1], af[1]] = slice_values[:, 4]
    cube.faces[r[2], c[2], af[2]] = slice_values[:, 1]
    cube.faces[r[3], c[3], af[3]] = slice_values[:, 2]
    cube.faces[r[4], c[4], af[4]] = slice_values[:, 3]

    cube
end

function slice_clockwise(cube::MagicCube, face::Int, layer::Int)
    newcube = MagicCube(cube)
    slice_clockwise!(newcube, face, layer)
end

function slice_counterclockwise!(cube::MagicCube, face::Int, layer::Int)
    if layer == 1
        return face_counterclockwise!(cube, face)
    elseif layer == cube.n
        return face_clockwise!(cube, opposite_face[face])
    end

    slice_values = adjacent_slice_values(cube, face, layer)

    # Rotate 90 degrees counter-clockwise.
    af = adjacent_faces(Val(face))
    r = slice_rows(Val(face), layer, cube.n)
    c = slice_cols(Val(face), layer, cube.n)
    cube.faces[r[1], c[1], af[1]] = slice_values[:, 2]
    cube.faces[r[2], c[2], af[2]] = slice_values[:, 3]
    cube.faces[r[3], c[3], af[3]] = slice_values[:, 4]
    cube.faces[r[4], c[4], af[4]] = slice_values[:, 1]

    cube
end

function slice_counterclockwise(cube::MagicCube, face::Int, layer::Int)
    newcube = MagicCube(cube)
    slice_counterclockwise!(newcube, face, layer)
end

"""
    cube_clockwise!(cube, face)

Rotate whole cube 90 degrees clockwise around the axis passing through `face` (orthogonal,
or normal to it).

"""
function cube_clockwise!(cube::MagicCube, face::Int)
    faces = adjacent_faces(Val(face))
    tmp = cube.faces[:, :, faces[1]]
    cube.faces[:, :, faces[1]] = cube.faces[:, :, faces[4]]
    cube.faces[:, :, faces[4]] = cube.faces[:, :, faces[3]]
    cube.faces[:, :, faces[3]] = cube.faces[:, :, faces[2]]
    cube.faces[:, :, faces[2]] = tmp
    cube
end

function cube_clockwise(cube::MagicCube, face::Int)
    newcube = MagicCube(cube)
    cube_clockwise!(newcube, face)
end

"""
    cube_counterclockwise!(cube, face)

Rotate whole cube 90 degrees counter-clockwise around the axis passing through `face` as you
look at `face` (orthogonal, or normal to it).

"""
function cube_counterclockwise!(cube::MagicCube, face::Int)
    faces = adjacent_faces(Val(face))
    tmp = cube.faces[:, :, faces[1]]
    cube.faces[:, :, faces[1]] = cube.faces[:, :, faces[2]]
    cube.faces[:, :, faces[2]] = cube.faces[:, :, faces[3]]
    cube.faces[:, :, faces[3]] = cube.faces[:, :, faces[4]]
    cube.faces[:, :, faces[4]] = tmp
    cube
end

function cube_counterclockwise(cube::MagicCube, face::Int)
    newcube = MagicCube(cube)
    cube_counterclockwise!(newcube, face)
end


"""
    show(io, cube)

Print cube unrolled centered on face 1.

Format:
```
  4
2 1 3 6
  5
```

"""
function Base.show(io::IO, cube::MagicCube)
    n = cube.n

    # Print face 4 on top.
    for i = 1:n
        _print_offset(n)
        for c in cube.faces[i, :, 4]
            print(c)
        end
        println()
    end

    # Print faces 2, 1, 3, and 6 on next row.
    for i = 1:n
        for face in [2, 1, 3, 6]
            for c in cube.faces[i, :, face]
                print(c)
            end
        end
        println()
    end

    # Print face 5 on bottom.
    for i = 1:n
        _print_offset(n)
        for c in cube.faces[i, :, 5]
            print(c)
        end
        println()
    end
end

function _print_offset(n)
    for i in 1:n
        print(" ")
    end
end

# Shortcut moves based on speed cube notation.  Slices default to assuming a MagicCube(3).
L!(cube::MagicCube) = face_clockwise!(cube, 2)
Lp!(cube::MagicCube) = face_counterclockwise!(cube, 2)
R!(cube::MagicCube) = face_clockwise!(cube, 3)
Rp!(cube::MagicCube) = face_counterclockwise!(cube, 3)
U!(cube::MagicCube) = face_clockwise!(cube, 4)
Up!(cube::MagicCube) = face_counterclockwise!(cube, 4)
D!(cube::MagicCube) = face_clockwise!(cube, 5)
Dp!(cube::MagicCube) = face_counterclockwise!(cube, 5)
F!(cube::MagicCube) = face_clockwise!(cube, 1)
Fp!(cube::MagicCube) = face_counterclockwise!(cube, 1)
B!(cube::MagicCube) = face_clockwise!(cube, 6)
Bp!(cube::MagicCube) = face_counterclockwise!(cube, 6)


M!(cube::MagicCube, layer=2) = slice_clockwise!(cube, 2, layer)
Mp!(cube::MagicCube, layer=2) = slice_counterclockwise!(cube, 2, layer)
E!(cube::MagicCube, layer=2) = slice_clockwise!(cube, 5, layer)
Ep!(cube::MagicCube, layer=2) = slice_counterclockwise!(cube, 5, layer)
S!(cube::MagicCube, layer=2) = slice_clockwise!(cube, 1, layer)
Sp!(cube::MagicCube, layer=2) = slice_counterclockwise!(cube, 1, layer)

X!(cube::MagicCube) = cube_clockwise!(cube, 3)
Xp!(cube::MagicCube) = cube_counterclockwise!(cube, 3)
Y!(cube::MagicCube) = cube_clockwise!(cube, 4)
Yp!(cube::MagicCube) = cube_counterclockwise!(cube, 4)
Z!(cube::MagicCube) = cube_clockwise!(cube, 1)
Zp!(cube::MagicCube) = cube_counterclockwise!(cube, 1)

L(cube::MagicCube) = (newcube = MagicCube(cube); L!(newcube))
Lp(cube::MagicCube) = (newcube = MagicCube(cube); Lp!(newcube))
R(cube::MagicCube) = (newcube = MagicCube(cube); R!(newcube))
Rp(cube::MagicCube) = (newcube = MagicCube(cube); Rp!(newcube))
U(cube::MagicCube) = (newcube = MagicCube(cube); U!(newcube))
Up(cube::MagicCube) = (newcube = MagicCube(cube); Up!(newcube))
D(cube::MagicCube) = (newcube = MagicCube(cube); D!(newcube))
Dp(cube::MagicCube) = (newcube = MagicCube(cube); Dp!(newcube))
F(cube::MagicCube) = (newcube = MagicCube(cube); F!(newcube))
Fp(cube::MagicCube) = (newcube = MagicCube(cube); Fp!(newcube))
B(cube::MagicCube) = (newcube = MagicCube(cube); B!(newcube))
Bp(cube::MagicCube) = (newcube = MagicCube(cube); Bp!(newcube))

M(cube::MagicCube) = (newcube = MagicCube(cube); M!(newcube))
Mp(cube::MagicCube) = (newcube = MagicCube(cube); Mp!(newcube))
E(cube::MagicCube) = (newcube = MagicCube(cube); E!(newcube))
Ep(cube::MagicCube) = (newcube = MagicCube(cube); Ep!(newcube))
S(cube::MagicCube) = (newcube = MagicCube(cube); S!(newcube))
Sp(cube::MagicCube) = (newcube = MagicCube(cube); Sp!(newcube))


X(cube::MagicCube) = (newcube = MagicCube(cube); X!(newcube))
Xp(cube::MagicCube) = (newcube = MagicCube(cube); Xp!(newcube))
Y(cube::MagicCube) = (newcube = MagicCube(cube); Y!(newcube))
Yp(cube::MagicCube) = (newcube = MagicCube(cube); Yp!(newcube))
Z(cube::MagicCube) = (newcube = MagicCube(cube); Z!(newcube))
Zp(cube::MagicCube) = (newcube = MagicCube(cube); Zp!(newcube))

const SUCESSOR_MOVES! = [
    L!, Lp!, R!, Rp!, U!, Up!, D!, Dp!, F!, Fp!, B!, Bp!, M!, Mp!, E!, Ep!,
    S!, Sp!]
const POSSIBLE_MOVES! = [
    L!, Lp!, R!, Rp!, U!, Up!, D!, Dp!, F!, Fp!, B!, Bp!, M!, Mp!, E!, Ep!,
    S!, Sp!, X!, Xp!, Y!, Yp!, Z!, Zp!]
const SUCESSOR_MOVES = [
    L, Lp, R, Rp, U, Up, D, Dp, F, Fp, B, Bp, M, Mp, E, Ep,
    S, Sp]
const POSSIBLE_MOVES = [
    L, Lp, R, Rp, U, Up, D, Dp, F, Fp, B, Bp, M, Mp, E, Ep,
    S, Sp, X, Xp, Y, Yp, Z, Zp]


function shuffle!(cube::MagicCube, n=3)
    moves = rand(SUCESSOR_MOVES!, n)
    for m! in moves
        m!(cube)
    end
    cube
end

function shuffle(cube::MagicCube, n=3)
    newcube = MagicCube(cube)
    shuffle!(newcube, n)
end


function solved(cube::MagicCube)
    for i = 1:6
        face_value = cube.faces[1, 1, i]
        match = true
        for col in 1:cube.n
            for row in 1:cube.n
                match &= face_value == cube.faces[row, col, i]
            end
        end
        if !match
            return false
        end
    end
    return true
end

"""
    MagicCubeIterState(cube)

Iterator over cube configurations reachable by one move excluding whole cube
rotations.

"""
mutable struct MagicCubeIterState
    next_face::Int
    next_layer::Int
    next_clockwise::Bool

    MagicCubeIterState() = new(1, 1, true)    
end

# Only need three of six faces because we can do clockwise and counterclockwise rotations.
const ITERATE_FACE_SEQUENCE = [1, 2, 4]

struct OneTurnNeighbors
    cube::MagicCube
end

Base.iterate(neighbors::OneTurnNeighbors) = (state = MagicCubeIterState(); iterate(neighbors, state))

function Base.iterate(neighbors::OneTurnNeighbors, state::MagicCubeIterState)
    newcube = MagicCube(neighbors.cube)

    # For each face, iterate all slices.
    if state.next_layer <= newcube.n
        next_face = ITERATE_FACE_SEQUENCE[state.next_face]
        if state.next_clockwise
            slice_clockwise!(newcube, next_face, state.next_layer)
            state.next_clockwise = false
        else
            slice_counterclockwise!(newcube, next_face, state.next_layer)
            state.next_clockwise = true
            state.next_layer += 1
        end
    else
        state.next_layer = 1
        state.next_face += 1
        if state.next_face <= 3
            next_face = ITERATE_FACE_SEQUENCE[state.next_face]
            # Since we just moved to a new face, we can guarantee clockwise is next.
            slice_clockwise!(newcube, next_face, state.next_layer)
            state.next_clockwise = false     
        else
            return nothing
        end
    end    

    newcube, state
end

function tree_search(cube::MagicCube, max_iter=1000)
    frontier = Queue{MagicCube}()
    enqueue!(frontier, cube)
    for i in 1:max_iter
        (length(frontier) == 0) && return nothing
        leaf = dequeue!(frontier)
        if solved(leaf) 
            println("Solved in $i iterations.")
            return leaf
        end
        for node in OneTurnNeighbors(leaf)
            enqueue!(frontier, node)
        end
    end
end


function graph_search(cube::MagicCube, max_iter=1000)
    frontier = Queue{MagicCube}()
    frontier_set = Set{MagicCube}()
    explored = Set{MagicCube}()
    push!(frontier_set, cube)
    enqueue!(frontier, cube)
    for i in 1:max_iter
        (length(frontier) == 0) && return nothing
        leaf = dequeue!(frontier)
        delete!(frontier_set, leaf)
        if solved(leaf) 
            println("Solved in $i iterations.")
            return leaf
        end
        push!(explored, leaf)
        for node in OneTurnNeighbors(leaf)
            if node ∉ explored && node ∉ frontier_set
                push!(frontier_set, node)
                enqueue!(frontier, node)
            end
        end
    end
end

end  # module Cube
