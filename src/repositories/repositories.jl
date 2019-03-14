#############
# Repo Type #
#############

type Repo <: GitLabType
    name::Union{String, Nothing}
    visibility_level::Union{Int, Nothing}
    homepage::Union{HttpCommon.URI, Nothing}
    git_http_url::Union{HttpCommon.URI, Nothing}
    description::Union{String, Nothing}
    project_id::Union{Int, Nothing}

    id::Union{Int, Nothing}
    default_branch::Union{String, Nothing}
    tag_list::Union{Vector{String}, Nothing}
    public::Union{Bool, Nothing}
    archived::Union{Bool, Nothing}
    ## TODO FIX ssh_url_to_repo::Union{HttpCommon.URI, Nothing}
    http_url_to_repo::Union{HttpCommon.URI, Nothing}
    web_url::Union{HttpCommon.URI, Nothing}
    owner::Union{Owner, Nothing}
    name_with_namespace::Union{String, Nothing}
    path::Union{String, Nothing}
    path_with_namespace::Union{String, Nothing}
    issues_enabled::Union{Bool, Nothing}
    merge_requests_enabled::Union{Bool, Nothing}
    wiki_enabled::Union{Bool, Nothing}
    builds_enabled::Union{Bool, Nothing}
    snippets_enabled::Union{Bool, Nothing}
    container_registry_enabled::Union{Bool, Nothing}
    created_at::Union{DateTime, Nothing}
    last_activity_at::Union{DateTime, Nothing}
    shared_runners_enabled::Union{Bool, Nothing}
    creator_id::Union{Int, Nothing}
    ## TODO FIX namespace::Union{Namespace, Nothing}
    ## \"namespace\":{\"id\":2,\"name\":\"mdpradeep\",\"path\":\"mdpradeep\",\"owner_id\":2,\"created_at\":\"2016-06-17T07:09:56.494Z\",\"updated_at\":\"2016-06-17T07:09:56.494Z\",\"description\":\"\",\"avatar\":null,\"share_with_group_lock\":false,\"visibility_level\":20}
    avatar_url::Union{HttpCommon.URI, Nothing}
    star_count::Union{Int, Nothing}
    forks_count::Union{Int, Nothing}
    open_issues_count::Union{Int, Nothing}
    runners_token::Union{String, Nothing}
    public_builds::Union{Bool, Nothing}
    ## TODO permissions::Union{Permissions, Nothing}
    ## \"permissions\":{\"project_access\":{\"access_level\":40,\"notification_level\":3},\"group_access\":null}
end

Repo(data::Dict) = json2gitlab(Repo, data)
## MDP Repo(full_name::AbstractString) = Repo(Dict("full_name" => full_name))
Repo(full_name::AbstractString) = Repo(Dict("name" => full_name))

## MDP namefield(repo::Repo) = repo.full_name
namefield(repo::Repo) = repo.name

###############
# API Methods #
###############

# repos #
#-------#

function repo_by_name(repo_name; options...)
    result = gh_get_json("/api/v3/projects/search/$(repo_name)"; options...)
    return Repo(result[1])
end

function repo(id; options...)
    ## result = gh_get_json("/repos/$(name(repo_obj))"; options...)
    result = gh_get_json("/api/v3/projects/$(id)"; options...)
    return Repo(result)
end

# forks #
#-------#

function forks(repo; options...)
    error("Not implemented yet !!")
    ## TODO
    ## results, page_data = gh_get_paged_json("/repos/$(name(repo))/forks"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(repo.id)/forks"; options...)
    return map(Repo, results), page_data
end

function create_fork(repo; options...)
    ## result = gh_post_json("/repos/$(name(repo))/forks"; options...)
    result = gh_post_json("/api/v3/projects/fork/$(repo.id)"; options...)
    return Repo(result)
end

function delete_fork(repo; options...)
    ## /projects/:id/fork
    result = gh_delete_json("/api/v3/projects/$(repo.id)/fork"; options...)
    return Repo(result)
end

# contributors/collaborators #
#----------------------------#

function contributors(repo; options...)
    ## results, page_data = gh_get_paged_json("/repos/$(name(repo))/contributors"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/$(repo.id)/repository/contributors"; options...)
    results = [Dict("contributor" => Owner(i), "contributions" => i["commits"]) for i in results]
    return results, page_data
end

function collaborators(repo; options...)
    ## MDP results, page_data = gh_get_json("/repos/$(name(repo))/collaborators"; options...)
    ## MDP results, page_data = gh_get_json("/api/v3/projects/$(repo.id)/repository/contributors"; options...)
    ## results, page_data = gh_get_paged_json("/api/v3/projects/$(repo.id)/members"; options...)
    results = gh_get_json("/api/v3/projects/$(repo.id)/members"; options...)
    return map(Owner, results)
end

function iscollaborator(repo, user; options...)
    collaborators = GitLab.collaborators(repo; options...)
    for c in collaborators
        if c.username == user
            return true
        end
    end

    return false
end

function add_collaborator(repo, user; options...)
    ## MDP path = "/repos/$(name(repo))/collaborators/$(name(user))"
    ## path = "/api/v3/projects/$(repo.id)/members/$(user)"
    ## return gh_put(path; options...)
    path = "/api/v3/projects/$(repo.id)/members"
    return gh_post(path; options...)
end

function remove_collaborator(repo, user; options...)
    ## MDP path = "/repos/$(name(repo))/collaborators/$(name(user))"
    ## path = "/api/v3/projects/$(repo.id))/repository/contributors/$(name(user)"
    path = "/api/v3/projects/$(repo.id)/members/$(user)"
    return gh_delete(path; options...)
end

# stats #
#-------#

## TODO Check how to enable sidekiq stats !
function stats(repo, stat, attempts = 3; options...)
    ## MDP path = "/repos/$(name(repo))/stats/$(name(stat))"
    ## path = "/api/v3/projects/$(repo.id))/repository/stats/$(name(stat)"
    path = "/api/v3/projects/sidekiq/$(name(stat))"
    local r
    for a in 1:attempts
        r = gh_get(path; handle_error = false, options...)
        r.status == 200 && return r
        sleep(2.0)
    end
    return r
end
