###############
# Commit Type #
###############

type Commit <: GitLabType
    id::Union{GitLabString, Nothing}
    author_email::Union{GitLabString, Nothing}
    title::Union{GitLabString, Nothing}
    short_id::Union{GitLabString, Nothing}
    message::Union{GitLabString, Nothing}
    committer_name::Union{GitLabString, Nothing}
    ## parents::Union{Vector{Commit}, Nothing}
    parent_ids::Union{Vector{Any}, Nothing}
    authored_date::Union{GitLabString, Nothing}
    committer_email::Union{GitLabString, Nothing}
    ## author_name::Union{Owner, Nothing}
    author_name::Union{GitLabString, Nothing}
    committed_date::Union{GitLabString, Nothing}
    created_at::Union{GitLabString, Nothing}
end

Commit(data::Dict) = json2gitlab(Commit, data)
Commit(id::AbstractString) = Commit(Dict("id" => id))

namefield(commit::Commit) = commit.id

###############
# API Methods #
###############

function commits(repo; options...)
    ## MDP results, page_data = gh_get_paged_json("/repos/$(name(repo))/commits"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(get(repo.id))/repository/commits"; options...)
    return map(Commit, results), page_data
end

function commit(repo, sha; options...)
    ## MDP result = gh_get_json("/repos/$(name(repo))/commits/$(name(sha))"; options...)
    result = gh_get_json("/api/v3/projects/$(get(repo.id))/repository/commits/$(name(sha))"; options...)
    return Commit(result)
end
