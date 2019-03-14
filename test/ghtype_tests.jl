using Dates
using JSON
using Test
using GitLab, GitLab.name, GitLab.Branch

# This file tests various GitLabType constructors. To test for proper Nullable
# handling, most fields have been removed from the JSON samples used below.
# Sample fields were selected in order to cover the full range of type behavior,
# e.g. if the GitLabType has a few Nullable{DateTime} fields, at least one
# of those fields should be present in the JSON sample.

function test_show(g::GitLab.GitLabType)
    tmpio = IOBuffer()
    show(tmpio, g)

    # basically trivial, but proves that things aren't completely broken
    @test repr(g) == String(take!(tmpio))

    tmpio = IOBuffer()
    show(IOContext(tmpio, :compact => true), g)

    @test "$(typeof(g))($(repr(name(g))))" == String(take!(tmpio))
end

#########
# Owner #
#########

owner_json = JSON.parse(
"""
{
  "name": "octocat_name",
  "username": "octocat",
  "id": 1,
  "state": "active",
  "web_url": "https://GitHub.com/octocat",
  "avatar_url": "",
  "ownership_type": "User"
}
"""
)

owner_result = Owner(
    owner_json["name"],
    owner_json["username"],
    owner_json["id"],
    owner_json["state"],
    HTTP.URI(""),
    HTTP.URI(owner_json["web_url"]),
    owner_json["ownership_type"]
)

@test Owner(owner_json) == owner_result
@test name(Owner(owner_json["username"])) == name(owner_result)
## @test setindex!(GitLab.gitlab2json(owner_result), nothing, "username") == owner_json
@test setindex!(GitLab.gitlab2json(owner_result), "", "avatar_url") == owner_json

test_show(owner_result)

########
# Repo #
########

repo_json = JSON.parse(
"""
{
    "project_id": 1296269,
    "owner": {
        "username": "octocat"
    },
    "name": "octocat/Hello-World",
    "public": true,
    "web_url": "https://api.github.com/repos/octocat/Hello-World",
    "last_activity_at": "2011-01-26T19:06:43"
    }
"""
)

repo_result = Repo(
    repo_json["name"],
    nothing,
    nothing,
    nothing,
    nothing,
    repo_json["project_id"],
    nothing,
    nothing,
    nothing,
    repo_json["public"],
    nothing,
    nothing,
    HTTP.URI(repo_json["web_url"]),
    Owner(repo_json["owner"]),
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    DateTime(repo_json["last_activity_at"]),
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing
)

@test Repo(repo_json) == repo_result
@test name(Repo(repo_json["name"])) == name(repo_result)
## @test setindex!(GitLab.gitlab2json(repo_result), nothing, "avatar_url") == repo_json

test_show(repo_result)

##########
# Commit #
##########

commit_json = JSON.parse(
"""
{
    "id": "5c35ae1de7f6d6bfadf0186e165f7af6537e7da8",
    "short_id": "5c35ae1d",
    "title": "Fixed test",
    "author_name": "Pradeep Mudlapur",
    "author_email": "pradeep@juliacomputing.com",
    "created_at": "2016-07-21T12:40:40.000+05:30",
    "message": "Fixed test"
}
"""
)

commit_result = Commit(
    commit_json["id"],
    commit_json["author_email"],
    commit_json["title"],
    commit_json["short_id"],
    commit_json["message"],
    nothing,
    nothing,
    nothing,
    nothing,
    commit_json["author_name"],
    nothing,
    commit_json["created_at"]
)

@test Commit(commit_json) == commit_result
@test name(Commit(commit_json["id"])) == name(commit_result)
## @test setindex!(GitLab.gitlab2json(commit_result), nothing, "html_url") == commit_json

test_show(commit_result)

##########
# Branch #
##########

branch_json = JSON.parse(
"""
{
    "name": "branch1",
    "protected": false,
    "commit": {
      "id": "1c5008fbc343f8793055d155af2e760fc3c1b6be",
      "message": "test",
      "parent_ids": [
        "15b89b7edde90eabc33580799277cbed6d3e4331"
      ],
      "authored_date": "2016-07-15T17:26:55.000+05:30",
      "author_name": "Pradeep Mudlapur",
      "author_email": "pradeep@juliacomputing.com",
      "committed_date": "2016-07-15T17:26:55.000+05:30",
      "committer_name": "Pradeep Mudlapur",
      "committer_email": "pradeep@juliacomputing.com"
    }
}
"""
)

branch_result = Branch(
    branch_json["name"],
    branch_json["protected"],
    Commit(branch_json["commit"])
)

@test Branch(branch_json) == branch_result
@test name(Branch(branch_json["name"])) == name(branch_result)
## @test setindex!(GitLab.gitlab2json(branch_result), true, "protected") == branch_json

test_show(branch_result)

###########
# Comment #
###########

comment_json = JSON.parse(
"""
{
    "note": "Test ...",
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
"""
)

comment_result = Comment(
    nothing,
    comment_json["created_at"],
    nothing,
    comment_json["note"],
    Owner(comment_json["author"]),
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing,
    nothing
)


@test Comment(comment_json) == comment_result
## @test name(Comment(comment_json["id"])) == name(comment_result)
## @test setindex!(GitLab.gitlab2json(comment_result), nothing, "position") == comment_json

## TODO check this failure
## test_show(comment_result)

###########
# Content #
###########

content_json = JSON.parse(
"""
{
  "file_name": "file1",
  "file_path": "src/file1",
  "size": 52,
  "encoding": "base64",
  "content": "bmV3IGZpbGUKCmNoYW5nZQpjb21tZW50cwptb3JlIGNoYW5nZXMKbW9yZSBjaGFuZ2VzCg==",
  "ref": "master",
  "blob_id": "cce7fdffea49a72ec48b8055faa52a664f91b917",
  "commit_id": "5c35ae1de7f6d6bfadf0186e165f7af6537e7da8",
  "last_commit_id": "078beb463b6a21ff97fc1b93594f1e7063cd78da"
}
"""
)

content_result = Content(
    content_json["file_name"],
    content_json["file_path"],
    content_json["size"],
    content_json["encoding"],
    content_json["content"],
    content_json["ref"],
    content_json["blob_id"],
    content_json["commit_id"],
    content_json["last_commit_id"]
)

@test Content(content_json) == content_result
@test name(Content(content_json["file_path"])) == name(content_result)
## @test setindex!(GitLab.gitlab2json(content_result), nothing, "encoding") == content_json

test_show(content_result)

##########
# Status #
##########

status_json = JSON.parse(
"""
{
    "id": 31696,
    "sha": "5c35ae1de7f6d6bfadf0186e165f7af6537e7da8",
    "ref": "",
    "status": "pending",
    "name": "default",
    "target_url": null,
    "description": null,
    "created_at": "2016-07-26T08:23:49",
    "started_at": null,
    "finished_at": null,
    "allow_failure": false,
    "author": {
      "name": "Pradeep",
      "username": "mdpradeep",
      "id": 2,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e32a35a20817e0258e12665c9099422?s=80&d=identicon",
      "web_url": "http://104.197.141.88/u/mdpradeep"
    }
}
"""
)

status_result = Status(
    status_json["id"],
    nothing,
    nothing,
    nothing,
    nothing,
    status_json["sha"],
    nothing,
    nothing,
    DateTime(status_json["created_at"]),
    nothing,
    nothing,
    nothing,
    nothing,
    status_json["status"],
    status_json["name"],
    Owner(status_json["author"]),
    status_json["ref"],
    nothing,
    nothing,
    status_json["allow_failure"]
)

@test Status(status_json) == status_result
@test name(Status(status_json["id"])) == name(status_result)
## @test setindex!(GitLab.gitlab2json(status_result), nothing, "context") == status_json

test_show(status_result)

###############
# PullRequest #
###############

pr_json = JSON.parse(
"""
  {
    "id": 4,
    "iid": 4,
    "project_id": 1,
    "title": "test",
    "description": "",
    "state": "merged",
    "created_at": "2016-07-15T11:58:01.819",
    "updated_at": "2016-07-22T07:32:20.149",
    "target_branch": "master",
    "source_branch": "branch1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Administrator",
      "username": "siteadmin",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a3918c0a2d98a6606bd787c54e6e5268?s=80&d=identicon",
      "web_url": "http://104.197.141.88/u/siteadmin"
    },
    "assignee": null,
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "work_in_progress": false,
    "milestone": null,
    "merge_when_build_succeeds": false,
    "merge_status": "cannot_be_merged",
    "subscribed": true,
    "user_notes_count": 70
  }
"""
)

pr_result = PullRequest(
    pr_json["id"],
    pr_json["iid"],
    pr_json["project_id"],
    pr_json["title"],
    pr_json["description"],
    pr_json["state"],
    DateTime(pr_json["created_at"]),
    DateTime(pr_json["updated_at"]),
    pr_json["target_branch"],
    pr_json["source_branch"],
    pr_json["upvotes"],
    pr_json["downvotes"],
    Owner(pr_json["author"]),
    nothing, ## assignee
    pr_json["source_project_id"],
    pr_json["target_project_id"],
    pr_json["labels"]),
    pr_json["work_in_progress"],
    nothing, ## milestone
    pr_json["merge_when_build_succeeds"],
    pr_json["merge_status"],
    pr_json["subscribed"],
    pr_json["user_notes_count"]
)

@test PullRequest(pr_json) == pr_result
@test name(PullRequest(pr_json["id"])) == name(pr_result)
## @test GitLab.gitlab2json(pr_result) == pr_json

test_show(pr_result)

#########
# Issue #
#########

issue_json = JSON.parse(
"""
{
  "id": 1,
  "iid": 1,
  "project_id": 1,
  "title": "Test Issue 1",
  "description": "Test for webhooks ...",
  "state": "opened",
  "created_at": "2016-06-20T10:06:27.980",
  "updated_at": "2016-07-26T09:37:12.651",
  "labels": [
    "MyLabel"
  ],
  "milestone": null,
  "assignee": {
    "name": "Pradeep",
    "username": "mdpradeep",
    "id": 2,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e32a35a20817e0258e12665c9099422?s=80&d=identicon",
    "web_url": "http://104.197.141.88/u/mdpradeep"
  },
  "author": {
    "name": "Pradeep",
    "username": "mdpradeep",
    "id": 2,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e32a35a20817e0258e12665c9099422?s=80&d=identicon",
    "web_url": "http://104.197.141.88/u/mdpradeep"
  },
  "subscribed": true,
  "user_notes_count": 12
}
"""
)

issue_result = Issue(
    issue_json["id"],
    issue_json["iid"],
    issue_json["project_id"],
    issue_json["title"],
    issue_json["description"],
    issue_json["state"],
    DateTime(issue_json["created_at"]),
    DateTime(issue_json["updated_at"]),
    issue_json["labels"]),
    nothing, ## milestone
    Owner(issue_json["assignee"]),
    Owner(issue_json["author"]),
    issue_json["subscribed"],
    issue_json["user_notes_count"]
)

@test Issue(issue_json) == issue_result
@test name(Issue(issue_json["id"])) == name(issue_result)
## @test setindex!(GitLab.gitlab2json(issue_result), nothing, "closed_at") == issue_json

test_show(issue_result)
