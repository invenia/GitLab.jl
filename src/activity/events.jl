#####################
# WebhookEvent Type #
#####################

struct WebhookEvent
    kind::String
    payload::Dict
    repository::Repo
    sender::Owner
end

function event_from_payload!(kind, data::Dict)
    ## @show data
    if haskey(data, "repository")
        data["repository"]["id"] = data["project_id"] ## Repos are identified through projects !
        repository = Repo(data["repository"])
    elseif kind == "membership"
        repository = Repo("")
    else
        error("event payload is missing repository field")
    end

    ## @show repository
    #= TODO CHECK
    if haskey(data, "sender")
        sender = Owner(data["sender"])
    else
        error("event payload is missing sender")
    end
    =#
    if haskey(data["project"], "namespace")
        sender = Owner(data["project"]["namespace"])
    else
        error("event payload is missing sender")
    end

    return WebhookEvent(kind, data, repository, sender)
end

########################
# Validation Functions #
########################

has_event_header(request::HTTP.Request) = haskey(request.headers, "X-Gitlab-Event")
event_header(request::HTTP.Request) = request.headers["X-Gitlab-Event"]

## has_sig_header(request::HTTP.Request) = haskey(request.headers, "X-Hub-Signature")
## sig_header(request::HTTP.Request) = request.headers["X-Hub-Signature"]
has_sig_header(request::HTTP.Request) = haskey(request.headers, "X-Gitlab-Token")
sig_header(request::HTTP.Request) = request.headers["X-Gitlab-Token"]

function has_valid_secret(request::HTTP.Request, secret)
    if has_sig_header(request)
        secret_sha = "sha1="*bytes2hex(MbedTLS.digest(MbedTLS.MD_SHA1, request.data, secret))
        @show sig_header(request), secret_sha
        return sig_header(request) == secret_sha
    end
    return false
end

function is_valid_event(request::HTTP.Request, events)
    return (has_event_header(request) && in(event_header(request), events))
end

function from_valid_repo(event, repos)
    return (name(event.repository) == "" || in(name(event.repository), repos))
end

#################
# EventListener #
#################

struct EventListener
    server::HTTP.Servers.Server  # TODO: This probably needs to be overhauled (see GitHub.jl).
    function EventListener(handle; auth::Authorization = AnonymousAuth(),
                           secret = nothing, events = nothing,
                           repos = nothing, forwards = nothing)
        if forwards !== nothing
            forwards = map(HTTP.URI, forwards)
        end

        if repos !== nothing
            repos = map(name, repos)
        end

        server = HttpServer.Server() do request, response
            try
                handle_event_request(request, handle; auth = auth,
                                     secret = secret, events = events,
                                     repos = repos, forwards = forwards)
            catch err
                println("SERVER ERROR: $err\n$(join(catch_stacktrace(), "\n"))")
                return HTTP.Response(500)
            end
        end

        server.http.events["listen"] = port -> begin
            println("Listening for GitLab events sent to $port;")
            println("Whitelisted events: $(something(events, "All"))")
            println("Whitelisted repos: $(something(repos, "All"))")
        end

        return new(server)
    end
end

function handle_event_request(request, handle;
                              auth::Authorization = AnonymousAuth(),
                              secret = nothing, events = nothing,
                              repos = nothing, forwards = nothing)
    #=
    @show secret, events, auth, handle
    @show request.method
    @show request.resource
    @show request.headers
    @show UTF8String(request.data)
    @show request.uri
    if secret !== nothing && !(has_valid_secret(request, secret))
        ## MDP TODO
        println("FIX ME !!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        ## MDP return HTTP.Response(400, "invalid signature")
    end
    =#

    if events !== nothing && !(is_valid_event(request, events))
        return HTTP.Response(400, "invalid event")
    end

    event = event_from_payload!(event_header(request), Requests.json(request))

    if repos !== nothing && !(from_valid_repo(event, repos))
        return HTTP.Response(400, "invalid repo")
    end

    if forwards !== nothing
        for address in forwards
            Requests.post(address, request)
        end
    end

    return handle(event)
end

function Base.run(listener::EventListener, args...; kwargs...)
    return HttpServer.run(listener.server, args...; kwargs...)
end

###################
# CommentListener #
###################

#=
const COMMENT_EVENTS = ["commit_comment",
                        "pull_request",
                        "pull_request_review_comment",
                        "issues",
                        "issue_comment"]
=#

const COMMENT_EVENTS = ["Note Hook",
                        "MergeRequest",
                        "pull_request_review_comment",
                        "issues",
                        "issue_comment"]

struct CommentListener
    listener::EventListener
    function CommentListener(handle, trigger::Regex;
                             auth::Authorization = AnonymousAuth(),
                             check_collab::Bool = true,
                             secret = nothing,
                             repos = nothing,
                             forwards = nothing)
            listener = EventListener(auth=auth, secret=secret,
                                 events=COMMENT_EVENTS, repos=repos,
                                 forwards=forwards) do event
            return handle_comment(handle, event, auth, trigger, check_collab)
        end
        return new(listener)
    end
end

function Base.run(listener::CommentListener, args...; kwargs...)
    return run(listener.listener, args...; kwargs...)
end

function handle_comment(handle, event::WebhookEvent, auth::Authorization,
                        trigger::Regex, check_collab::Bool)
    kind, payload = event.kind, event.payload

    if (kind == "pull_request" || kind == "issues") && payload["action"] == "opened"
        body_container = kind == "issues" ? payload["issue"] : payload["pull_request"]
    elseif haskey(payload, "object_attributes")
        body_container = payload["object_attributes"]
    else
        return HTTP.Response(204, "payload does not contain comment")
    end

    if check_collab
        repo = event.repository
        user = payload["user"]["username"]
        if !(iscollaborator(repo, user; params = Dict("private_token" => auth.token)))
            return HTTP.Response(204, "commenter is not collaborator")
        end
    end

    ## MDP trigger_match = match(trigger, body_container["body"])
    trigger_match = match(trigger, body_container["note"])

    if trigger_match == nothing
        return HTTP.Response(204, "trigger match not found")
    end

    return handle(event, trigger_match)
end
