##############
# Owner Type #
##############


type Owner <: GitLabType
    name::Union{GitLabString, Nothing}
    username::Union{GitLabString, Nothing}
    id::Union{Int, Nothing}
    state::Union{GitLabString, Nothing}
    avatar_url::Union{HttpCommon.URI, Nothing}
    web_url::Union{HttpCommon.URI, Nothing}
    ownership_type::Union{GitLabString, Nothing}

#=
    email::Union{GitLabString, Nothing}
    bio::Union{GitLabString, Nothing}
    company::Union{GitLabString, Nothing}
    location::Union{GitLabString, Nothing}
    gravatar_id::Union{GitLabString, Nothing}
    public_repos::Union{Int, Nothing}
    owned_private_repos::Union{Int, Nothing}
    total_private_repos::Union{Int, Nothing}
    public_gists::Union{Int, Nothing}
    private_gists::Union{Int, Nothing}
    followers::Union{Int, Nothing}
    following::Union{Int, Nothing}
    collaborators::Union{Int, Nothing}
    html_url::Union{HttpCommon.URI, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    date::Union{Dates.DateTime, Nothing}
    hireable::Union{Bool, Nothing}
    site_admin::Union{Bool, Nothing}
=#
end

function Owner(data::Dict)
    o = json2gitlab(Owner, data)
    isnull(o.username) ? o.ownership_type = Nullable("Organization") : o.ownership_type = Nullable("User")
    o
end

Owner(username::AbstractString, isorg = false) = Owner(
    Dict("username" => isorg ? "" : username,
         "name" => isorg ? username : "",
         "ownership_type" => isorg ? "Organization" : "User"))
## Owner(username::AbstractString) = Owner(Dict("username" => username))

## namefield(owner::Owner) = owner.ownership_type == "Organization" ? owner.name : owner.username
namefield(owner::Owner) = isorg(owner) ? owner.name : owner.username

## typprefix(isorg) = isorg ? "orgs" : "users"
typprefix(isorg) = isorg ? "projects" : "users"

#############
# Owner API #
#############

isorg(owner::Owner) = isnull(owner.ownership_type) ? true : get(owner.ownership_type, "") == "Organization"

owner(owner_obj::Owner; options...) = owner(name(owner_obj), isorg(owner_obj); options...)

function owner(owner_obj, isorg = false; options...)
    ## TODO Need to look for a cleaner way of doing this ! Returns an array even while requesting a specific user
    if isorg
        result = gh_get_json("/api/v3/projects/search/$(owner_obj)"; options...)
        return Owner(result[1]["owner"])
    else
        result = gh_get_json("/api/v3/users?username=$(owner_obj)"; options...)
        return Owner(result[1])
    end
end

function users(; options...)
    results, page_data = gh_get_paged_json("/api/v3/users"; options...)
    return map(Owner, results), page_data
end

function orgs(owner; options...)
    ## results, page_data = gh_get_paged_json("/api/v3/users/$(name(owner))/projects"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects"; options...)
    return map(Owner, results), page_data
end

#= TODO: There seems to be no equivalent for these APIs
function followers(owner; options...)
    results, page_data = gh_get_paged_json("/api/v3/users/$(name(owner))/followers"; options...)
    return map(Owner, results), page_data
end

function following(owner; options...)
    results, page_data = gh_get_paged_json("/api/v3/users/$(name(owner))/following"; options...)
    return map(Owner, results), page_data
end
=#

repos(owner::Owner; options...) = repos(name(owner), isorg(owner); options...)

function repos(owner, isorg = false; options...)
    ## results, page_data = gh_get_paged_json("/api/v3/$(typprefix(isorg))/$(name(owner))/repos"; options...)
    results, page_data = gh_get_paged_json("/api/v3/projects/owned"; options...)
    return map(Repo, results), page_data
end
