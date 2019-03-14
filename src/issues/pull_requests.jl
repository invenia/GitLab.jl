####################
# PullRequest Type #
####################

type PullRequest <: GitLabType
    id::Union{Int, Nothing}
    iid::Union{Int, Nothing}
    project_id::Union{Int, Nothing}
    title::Union{GitLabString, Nothing}
    description::Union{GitLabString, Nothing}
    state::Union{GitLabString, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    target_branch::Union{GitLabString, Nothing}
    source_branch::Union{GitLabString, Nothing}
    upvotes::Union{Int, Nothing}
    downvotes::Union{Int, Nothing}
    author::Union{Owner, Nothing}
    assignee::Union{Owner, Nothing}
    source_project_id::Union{Int, Nothing}
    target_project_id::Union{Int, Nothing}
    labels::Union{Vector{GitLabString}, Nothing}
    work_in_progress::Union{Bool, Nothing}
    milestone::Union{GitLabString, Nothing}
    merge_when_build_succeeds::Union{Bool, Nothing}
    merge_status::Union{GitLabString, Nothing}
    subscribed::Union{Bool, Nothing}
    user_notes_count::Union{Int, Nothing}


#=
    base::Union{Branch, Nothing}
    head::Union{Branch, Nothing}
    number::Union{Int, Nothing}
    comments::Union{Int, Nothing}
    commits::Union{Int, Nothing}
    additions::Union{Int, Nothing}
    deletions::Union{Int, Nothing}
    changed_files::Union{Int, Nothing}
    merge_commit_sha::Union{GitLabString, Nothing}
    closed_at::Union{Dates.DateTime, Nothing}
    merged_at::Union{Dates.DateTime, Nothing}
    url::Union{HttpCommon.URI, Nothing}
    html_url::Union{HttpCommon.URI, Nothing}
    merged_by::Union{Owner, Nothing}
    _links::Union{Dict, Nothing}
    mergeable::Union{Bool, Nothing}
    merged::Union{Bool, Nothing}
    locked::Union{Bool, Nothing}
=#
end

PullRequest(data::Dict) = json2gitlab(PullRequest, data)
PullRequest(id::Int) = PullRequest(Dict("id" => id))

namefield(pr::PullRequest) = pr.id

###############
# API Methods #
###############

function pull_requests(repo::Repo; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(get(repo.id))/merge_requests"; options...)
    return map(PullRequest, results), page_data
end

function pull_request(repo::Repo, pr::Int; options...)
    result = gh_get_json("/api/v3/projects/$(get(repo.id))/merge_requests/$(pr)"; options...)
    return PullRequest(result)
end
