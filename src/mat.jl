const CMat = Ptr{Cvoid}

"""
    A Petsc matrix, actually just a pointer to the actual C matrix
"""
struct PetscMat
    ptr::Ref{CMat}

    PetscMat() = new(Ref{CMat}())
end


# allows us to pass PetscMat objects directly into CMat ccall signatures
Base.cconvert(::Type{CMat}, mat::PetscMat) = mat.ptr[]

"""
MatSetValue(mat::PetscMat, i::PetscInt, j::PetscInt, v::PetscScalar, mode::InsertMode)

Wrapper to `MatSetValue`. Indexing starts at 0 (as in PETSc).

# Implementation
For an unknow reason, calling PETSc.MatSetValue leads to an "undefined symbol: MatSetValue" error.
So this wrapper directly call MatSetValues (anyway, this is what is done in PETSc...)
"""
function MatSetValue(mat::PetscMat, i::PetscInt, j::PetscInt, v::PetscScalar, mode::InsertMode)
    MatSetValues(mat, PetscIntOne, [i], PetscIntOne, [j], [v], mode)
end

function MatSetValue(mat::PetscMat, i::Integer, j::Integer, v::Number, mode::InsertMode)
    MatSetValue(mat, PetscInt(i), PetscInt(j), PetscScalar(v), mode)
end

"""
MatSetValues(mat::PetscMat, nI::PetscInt, I::Vector{PetscInt}, nJ::PetscInt, J::Vector{PetscInt}, V::Array{PetscScalar}, mode::InsertMode)

Wrapper to `MatSetValues`. Indexing starts at 0 (as in PETSc)
"""
function MatSetValues(mat::PetscMat, nI::PetscInt, I::Vector{PetscInt}, nJ::PetscInt, J::Vector{PetscInt}, V::Array{PetscScalar}, mode::InsertMode)
    error = ccall((:MatSetValues, libpetsc), PetscErrorCode,
        (CMat, PetscInt, Ptr{PetscInt}, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode),
        mat, nI, I, nJ, J, V, mode)
    @assert iszero(error)
end

function MatSetValues(mat::PetscMat, I::Vector{PetscInt}, J::Vector{PetscInt}, V::Array{PetscScalar}, mode::InsertMode)
    MatSetValues(mat, PetscInt(length(I)), I, PetscInt(length(J)), J, V, mode)
end

function MatSetValues(mat::PetscMat, I, J, V, mode::InsertMode)
    MatSetValues(mat, PetscInt.(I), PetscInt.(collect(J)), PetscScalar.(V), mode)
end

"""
    MatCreate(comm::MPI.Comm, mat::PetscMat)

Wrapper to MatCreate
"""
function MatCreate(comm::MPI.Comm, mat::PetscMat)
    error = ccall((:MatCreate, libpetsc), PetscErrorCode, (MPI.MPI_Comm, Ptr{CMat}), comm, mat.ptr)
    @assert iszero(error)
end

function MatCreate(comm::MPI.Comm = MPI.COMM_WORLD)
    mat = PetscMat()
    MatCreate(comm, mat)
    return mat
end

"""
    MatSetSizes(mat::PetscMat, nrows_loc, ncols_loc, nrows_glo, ncols_glo)

Wrapper to MatSetSizes
"""
function MatSetSizes(mat::PetscMat, nrows_loc, ncols_loc, nrows_glo, ncols_glo)
    nr_loc = PetscInt(nrows_loc)
    nc_loc = PetscInt(ncols_loc)
    nr_glo = PetscInt(nrows_glo)
    nc_glo = PetscInt(ncols_glo)
    error = ccall((:MatSetSizes, libpetsc),
                PetscErrorCode,
                (CMat, PetscInt, PetscInt, PetscInt, PetscInt),
                mat, nr_loc, nc_loc, nr_glo, nc_glo
            )
    @assert iszero(error)
end


"""
    MatSetUp(mat::PetscMat)

Wrapper to MatSetUp
"""
function MatSetUp(mat::PetscMat)
    error = ccall((:MatSetUp, libpetsc), PetscErrorCode, (CMat,), mat)
    @assert iszero(error)
end


"""
    MatSetFromOptions(mat::PetscMat)

Wrapper to MatSetFromOptions
"""
function MatSetFromOptions(mat::PetscMat)
    error = ccall((:MatSetFromOptions, libpetsc), PetscErrorCode, (CMat,), mat)
    @assert iszero(error)
end

"""
    MatGetOwnershipRange(mat::PetscMat)

Wrapper to `MatGetOwnershipRange`

The result `(rstart, rend)` is a Tuple indicating the rows handled by the local processor.

# Warning
`PETSc` indexing starts at zero (so `rstart` may be zero) and `rend-1` is the last row
handled by the local processor.
"""
function MatGetOwnershipRange(mat::PetscMat)
    rstart = Ref{PetscInt}(0)
    rend = Ref{PetscInt}(0)

    error = ccall((:MatGetOwnershipRange, libpetsc), PetscErrorCode, (CMat, Ref{PetscInt}, Ref{PetscInt}), mat, rstart, rend)
    @assert iszero(error)

    return rstart[], rend[]
end

"""
    Wrapper to `MatAssemblyBegin`
"""
function MatAssemblyBegin(mat::PetscMat, type::MatAssemblyType)
    error = ccall((:MatAssemblyBegin, libpetsc), PetscErrorCode, (CMat, MatAssemblyType), mat, type)
    @assert iszero(error)
end

"""
    Wrapper to `MatAssemblyEnd`
"""
function MatAssemblyEnd(mat::PetscMat, type::MatAssemblyType)
    error = ccall((:MatAssemblyEnd, libpetsc), PetscErrorCode, (CMat, MatAssemblyType), mat, type)
    @assert iszero(error)
end


"""
    Wrapper to MatCreateVecs
"""
function MatCreateVecs(mat::PetscMat, vecr::PetscVec, veci::PetscVec)
    error = ccall((:MatCreateVecs, libpetsc), PetscErrorCode, (CMat, Ptr{CVec}, Ptr{CVec}), mat, vecr.ptr, veci.ptr)
    @assert iszero(error)
end

function MatCreateVecs(mat::PetscMat)
    vecr = PetscVec(); veci = PetscVec()
    MatCreateVecs(mat, vecr, veci)
    return vecr, veci
end

"""
    MatView(mat::PetscMat, viewer::PetscViewer = PetscViewerStdWorld())

Wrapper to `MatView`
"""
function MatView(mat::PetscMat, viewer::PetscViewer = PetscViewerStdWorld())
    error = ccall((:MatView, libpetsc), PetscErrorCode, (CMat, CViewer), mat, viewer)
    @assert iszero(error)
end

"""
    MatDestroy(mat::PetscMat)

Wrapper to MatDestroy
"""
function MatDestroy(mat::PetscMat)
    error = ccall((:MatDestroy, libpetsc), PetscErrorCode, (Ptr{CMat},), mat.ptr)
    @assert iszero(error)
end

"""
    MatCreateComposite(mat::PetscMat, smat::PetscMat)

Wrapper to `MatCompositeAddMat`
"""
# comm::MPI.Comm = MPI.COMM_WORLD
function MatCreateComposite(comm::MPI.Comm, nmat::PetscInt, mats::Vector{PetscMat}, mat::PetscMat)
    error = ccall((:MatCompositeAddMat, libpetsc), PetscErrorCode, (MPI.MPI_Comm, PetscInt, Ptr{CMat}, Ptr{CMat}),
                  comm, nmat, [x.ptr for x in mats], mat.ptr)
    @assert iszero(error)
end

function MatCreateComposite(comm::MPI.Comm, nmat::Integer, mats::Vector{PetscMat}, mat::PetscMat)
    MatCreateComposite(comm, PetscInt(nmat), mats, mat)
end

function MatCreateComposite(nmat::PetscInt, mats::Vector{PetscMat}, mat::PetscMat)
    MatCreateComposite(MPI.COMM_WORLD, nmat, mats, mat)
end

function MatCreateComposite(nmat::Integer, mats::Vector{PetscMat}, mat::PetscMat)
    MatCreateComposite(MPI.COMM_WORLD, PetscInt(nmat), mats, mat)
end
