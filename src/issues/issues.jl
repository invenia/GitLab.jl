##############
# Issue type #
##############

struct Issue <: GitLabType
    id::Union{Int, Nothing}
    iid::Union{Int, Nothing}
    project_id::Union{Int, Nothing}
    title::Union{String, Nothing}
    description::Union{String, Nothing}
    state::Union{String, Nothing}
    created_at::Union{DateTime, Nothing}
    updated_at::Union{DateTime, Nothing}
    ## labels::Union{Vector{Dict}, Nothing}
    labels::Union{Vector{String}, Nothing}
    milestone::Union{String, Nothing}
    assignee::Union{Owner, Nothing}
    author::Union{Owner, Nothing}
    subscribed::Union{Bool, Nothing}
    user_notes_count::Union{Int, Nothing}

#=
    closed_by::Union{Owner, Nothing}
    closed_at::Union{DateTime, Nothing}
    pull_request::Union{PullRequest, Nothing}
    url::Union{HttpCommon.URI, Nothing}
    html_url::Union{HttpCommon.URI, Nothing}
    labels_url::Union{HttpCommon.URI, Nothing}
    comments_url::Union{HttpCommon.URI, Nothing}
    events_url::Union{HttpCommon.URI, Nothing}
    locked::Union{Bool, Nothing}
=#
end

Issue(data::Dict) = json2gitlab(Issue, data)
Issue(id::Int) = Issue(Dict("id" => id))

namefield(issue::Issue) = issue.id

###############
# API Methods #
###############

function issue(repo::Repo, issue::Int; options...)
    result = gh_get_json("/api/v3/projects/$(repo.id)/issues/$(issue)"; options...)
    return Issue(result)
end

function issues(repo::Repo; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(repo.id)/issues"; options...)
    return map(Issue, results), page_data
end

function create_issue(repo::Repo; options...)
    result = gh_post_json("/api/v3/projects/$(repo.id)/issues"; options...)
    return Issue(result)
end

function edit_issue(repo::Repo, issue::Int; options...)
    result = gh_put_json("/api/v3/projects/$(repo.id)/issues/$(issue)"; options...)
    return Issue(result)
end

function delete_issue(repo::Repo, issue::Int; options...)
    result = gh_delete_json("/api/v3/projects/$(repo.id)/issues/$(issue)"; options...)
    return Issue(result)
end
