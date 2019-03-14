###############
# Status type #
###############

type Status <: GitLabType
    id::Union{Int, Nothing}
    total_count::Union{Int, Nothing}
    state::Union{GitLabString, Nothing}
    description::Union{GitLabString, Nothing}
    context::Union{GitLabString, Nothing}
    sha::Union{GitLabString, Nothing}
    url::Union{HttpCommon.URI, Nothing}
    target_url::Union{HttpCommon.URI, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    creator::Union{Owner, Nothing}
    repository::Union{Repo, Nothing}
    statuses::Union{Vector{Status}, Nothing}

    ## For commit status
    status::Union{GitLabString, Nothing}
    name::Union{GitLabString, Nothing}
    author::Union{Owner, Nothing}
    ref::Union{GitLabString, Nothing}
    started_at::Union{Dates.DateTime, Nothing}
    finished_at::Union{Dates.DateTime, Nothing}
    allow_failure::Union{Bool, Nothing}
end

Status(data::Dict) = json2gitlab(Status, data)
Status(id::Real) = Status(Dict("id" => id))

namefield(status::Status) = status.id

###############
# API Methods #
###############

function create_status(repo, sha; options...)
    result = gh_post_json("/api/v3/projects/$(get(repo.id))/statuses/$(name(sha))"; options...)
    return Status(result)
end

function statuses(repo, ref; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(get(repo.id))/repository/commits/$(name(ref))/statuses"; options...)
    return map(Status, results), page_data
end

#= TODO: no equivalent API
function status(repo, ref; options...)
    result = gh_get_json("/api/v3/projects/$(get(repo.id))/commits/$(name(ref))/status"; options...)
    return Status(result)
end
=#
