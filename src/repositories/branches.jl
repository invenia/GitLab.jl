###############
# Branch Type #
###############

struct Branch <: GitLabType
    name::Union{String, Nothing}
    protected::Union{Bool, Nothing}
    commit::Union{Commit, Nothing}
#=
    label::Union{String, Nothing}
    ref::Union{String, Nothing}
    sha::Union{String, Nothing}
    user::Union{Owner, Nothing}
    repo::Union{Repo, Nothing}
    _links::Union{Dict, Nothing}
    protection::Union{Dict, Nothing}
=#
end

Branch(data::Dict) = json2gitlab(Branch, data)
Branch(name::AbstractString) = Branch(Dict("name" => name))

## namefield(branch::Branch) = branch.name === nothing ? branch.ref : branch.name
namefield(branch::Branch) = branch.name

###############
# API Methods #
###############

function branches(repo; options...)
    ## MDP results, page_data = gh_get_paged_json("/repos/$(name(repo))/branches"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(repo.id)/repository/branches"; options...)
    return map(Branch, results), page_data
end

function branch(repo, branch; options...)
    ## result = gh_get_json("/repos/$(name(repo))/branches/$(name(branch))"; options...)
    result = gh_get_json("/api/v3/projects/$(repo.id)/repository/branches/$(name(branch))"; options...)
    return Branch(result)
end
