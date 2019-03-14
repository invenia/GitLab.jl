################
# Content Type #
################



type Content <: GitLabType
    file_name::Union{GitLabString, Nothing}
    file_path::Union{GitLabString, Nothing}
    size::Union{Int, Nothing}
    encoding::Union{GitLabString, Nothing}
    content::Union{GitLabString, Nothing}
    ref::Union{GitLabString, Nothing}
    blob_id::Union{GitLabString, Nothing}
    commit_id::Union{GitLabString, Nothing}
    last_commit_id::Union{GitLabString, Nothing}

#=
    typ::Union{GitLabString, Nothing}
    name::Union{GitLabString, Nothing}
    target::Union{GitLabString, Nothing}
    url::Union{HttpCommon.URI, Nothing}
    git_url::Union{HttpCommon.URI, Nothing}
    html_url::Union{HttpCommon.URI, Nothing}
    download_url::Union{HttpCommon.URI, Nothing}
=#
end

Content(data::Dict) = json2gitlab(Content, data)
Content(file_path::AbstractString) = Content(Dict("file_path" => file_path))

namefield(content::Content) = content.file_path

###############
# API Methods #
###############

function file(repo, path, ref; options...)
    result = gh_get_json(content_uri(repo, path, ref); options...)
    return Content(result)
end

#= TODO No equivalent API
function directory(repo, path; options...)
    results, page_data = gh_get_paged_json(content_uri(repo, path); options...)
    return map(Content, results), page_data
end
=#

function create_file(repo, path; options...)
    result = gh_put_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function update_file(repo, path; options...)
    result = gh_put_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function delete_file(repo, path; options...)
    result = gh_delete_json(content_uri(repo, path); options...)
    return build_content_response(result)
end

function readme(repo; options...)
    ## result = gh_get_json("/api/v3/projects/$(get(repo.id))/readme"; options...)
    result = gh_get_json(content_uri(repo, "README.md"); options...)
    return Content(result)
end

function permalink(content::Content, commit)
    url = string(get(content.html_url))
    prefix = get(content.typ) == "file" ? "blob" : "tree"
    rgx = Regex(string("\/", prefix, "\/.*?\/"))
    replacement = string("/", prefix, "/", name(commit), "/")
    return HttpCommon.URI(replace(url, rgx, replacement))
end

###########################
# Content Utility Methods #
###########################

## content_uri(repo, path) = "/api/v3/projects/$(get(repo.id))/contents/$(name(path))"
## content_uri(repo, path) = "/api/v3/projects/$(get(repo.id))/files"
content_uri(repo, path, ref) = "/api/v3/projects/$(get(repo.id))/repository/files?file_path=$(name(path))&ref=$(name(ref))"
content_uri(repo, path) = "/api/v3/projects/$(get(repo.id))/repository/files?file_path=$(name(path))&ref=master"

function build_content_response(json::Dict)
    results = Dict()
    haskey(json, "commit") && setindex!(results, Commit(json["commit"]), "commit")
    haskey(json, "content") && setindex!(results, Content(json["content"]), "content")
    return results
end
