################
# Comment Type #
################

struct Comment <: GitLabType
    noteable_type::Union{String, Nothing}
    ## created_at::Union{DateTime, Nothing}
    created_at::Union{String, Nothing}
    line_code::Union{Int64, Nothing}
    note::Union{String, Nothing}
    author::Union{Owner, Nothing}
    author_id::Union{Int64, Nothing}
    updated_by_id::Union{String, Nothing}
    noteable_id::Union{Int64, Nothing}
    commit_id::Union{String, Nothing}
    system::Union{Bool, Nothing}
    url::Union{HTTP.URI, Nothing}
    is_award::Union{Bool, Nothing}
    st_diff::Union{String, Nothing}
    id::Union{Int64, Nothing}
    ## updated_at::Union{DateTime, Nothing}
    updated_at::Union{String, Nothing}
    project_id::Union{Int64, Nothing}
    attachment::Union{String, Nothing}
    ## type::Union{String, Nothing}
    path::Union{String, Nothing}
    line::Union{String, Nothing}
    line_type::Union{String, Nothing}

#=
    original_commit_id::Union{String, Nothing}
    original_position::Union{Int, Nothing}
    position::Union{Int, Nothing}
    html_url::Union{HTTP.URI, Nothing}
    issue_url::Union{HTTP.URI, Nothing}
    pull_request_url::Union{HTTP.URI, Nothing}
    user::Union{Owner, Nothing}
=#

#=
    ## Issue comment
    {
        "note": "Test ...",
        "path": null,
        "line": null,
        "line_type": null,
        "author": {
          "name": "Pradeep",
          "username": "mdpradeep",
          "id": 2,
          "state": "active",
          "avatar_url": "http://www.gravatar.com/avatar/7e32a35a20817e0258e12665c9099422?s=80&d=identicon",
          "web_url": "http://104.197.141.88/u/mdpradeep"
        },
        "created_at": "2016-07-16T16:02:12.923Z"
    }


    ## Merge request comment
  "noteable_type" => "MergeRequest"
  "created_at"    => "2016-07-19 09:45:27 UTC"
  "line_code"     => nothing
  "note"          => "`sayhello(\"ABC\", \"cool\")`"
  "author_id"     => 2
  "updated_by_id" => nothing
  "noteable_id"   => 4
  "commit_id"     => ""
  "system"        => false
  "url"           => "http://104.197.141.88/mdpradeep/TestProject1/merge_requests/4#note_134"
  "is_award"      => false
  "st_diff"       => nothing
  "id"            => 134
  "updated_at"    => "2016-07-19 09:45:27 UTC"
  "project_id"    => 1
  "attachment"    => nothing
  "type"          => nothing

    ## commit comment
  "noteable_type" => "Commit"
  "created_at"    => "2016-07-18 06:49:53 UTC"
  "line_code"     => nothing
  "note"          => "`sayhello(\\\"ABC\\\", \\\"cool\\\")`"
  "author_id"     => 2
  "updated_by_id" => nothing
  "noteable_id"   => nothing
  "commit_id"     => "d1d585d2fbc0c3a052e219f30504be8d1621a2a9"
  "system"        => false
  "url"           => "http://104.197.141.88/mdpradeep/TestProject1/commit/d1d585d2fbc0c3a052e219f30504be8d1621a2a9#note_46"
  "is_award"      => false
  "st_diff"       => nothing
  "id"            => 46
  "updated_at"    => "2016-07-18 06:49:53 UTC"
  "project_id"    => 1
  "attachment"    => nothing
  "type"          => nothing
=#

end

Comment(data::Dict) = json2gitlab(Comment, data)
Comment(id::Int) = Comment(Dict("id" => id))

namefield(comment::Comment) = comment.id

kind_err_str(kind) = ("Error building comment request: :$kind is not a valid kind of comment.\n"*
                      "The only valid comment kinds are: :issue, :review, :commit")
###############
# API Methods #
###############

function comment(repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        ## MDP path = "/repos/$(name(repo))/issues/comments/$(name(item))"
        path = "/api/v3/projects/$(repo.id)/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/api/v3/projects/$(repo.id)/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/api/v3/projects/$(repo.id)/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_get_json(path; options...))
end

function comments(repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        ## MDP path = "/repos/$(name(repo)/issues/$(name(item))/comments"
        path = "/api/v3/projects/$(repo.id)/issues/$(name(item))/notes"
    elseif kind == :review
        ## MDP path = "/api/v3/projects/$(repo.id)/pulls/$(name(item))/comments"
        path = "/api/v3/projects/$(repo.id)/merge_requests/$(name(item))/notes"
    elseif kind == :commit
        path = "/api/v3/projects/$(repo.id)/repository/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end

    results, page_data = gh_get_paged_json(path; options...)
    return map(Comment, results), page_data
end

function create_comment(repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        ## MDP path = "/repos/$(name(repo))/issues/$(name(item))/comments"
        path = "/api/v3/projects/$(repo.id)/issues/$(name(item))/notes"
    elseif kind == :review
        ## MDP path = "/repos/$(name(repo))/pulls/$(name(item))/comments"
        path = "/api/v3/projects/$(repo.id)/merge_requests/$(name(item))/notes"
    elseif kind == :commit
        ## MDP path = "/repos/$(name(repo))/commits/$(name(item))/comments"
        path = "/api/v3/projects/$(repo.id)/repository/commits/$(name(item))/comments"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_post_json(path; options...))
end

function edit_comment(repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        ## MDP path = "/repos/$(name(repo))/issues/comments/$(name(item))"
        path = "/api/v3/projects/$(repo.id)/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/api/v3/projects/$(repo.id)/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/api/v3/projects/$(repo.id)/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return Comment(gh_patch_json(path; options...))
end

function delete_comment(repo, item, kind = :issue; options...)
    if (kind == :issue) || (kind == :pr)
        path = "/api/v3/projects/$(repo.id)/issues/comments/$(name(item))"
    elseif kind == :review
        path = "/api/v3/projects/$(repo.id)/pulls/comments/$(name(item))"
    elseif kind == :commit
        path = "/api/v3/projects/$(repo.id)/comments/$(name(item))"
    else
        error(kind_err_str(kind))
    end
    return gh_delete(path; options...)
end
