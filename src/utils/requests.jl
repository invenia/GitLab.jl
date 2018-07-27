####################
# Default API URIs #
####################

const API_ENDPOINT = HTTP.URI(get(ENV, "API_ENDPOINT", "http://104.197.141.88/"))

api_uri(path) = HTTP.URI(API_ENDPOINT, path=path)

#######################
# GitLab REST Methods #
#######################

function gitlab_request(request_method, endpoint;
                        auth = AnonymousAuth(), handle_error = true,
                        headers = Dict(), params = Dict())
    authenticate_headers!(headers, auth)
    params = gitlab2json(params)
    api_endpoint = api_uri(endpoint)
    _headers = convert(Dict{String,String}, headers)
    if !haskey(_headers, "User-Agent")
        _headers["User-Agent"] = "GitLab-jl"
    end
    r = if request_method == HTTP.get
        request_method(merge(api_endpoint, query=params), _headers, status_exception=false, idle_timeout=20)
    else
        request_method(string(api_endpoint), _headers, JSON.json(params), status_exception=false, idle_timeout=20)
    end
    handle_error && handle_response_error(r)
    return r
end

gh_get(endpoint = ""; options...) = gitlab_request(HTTP.get, endpoint; options...)
gh_post(endpoint = ""; options...) = gitlab_request(HTTP.post, endpoint; options...)
gh_put(endpoint = ""; options...) = gitlab_request(HTTP.put, endpoint; options...)
gh_delete(endpoint = ""; options...) = gitlab_request(HTTP.delete, endpoint; options...)
gh_patch(endpoint = ""; options...) = gitlab_request(HTTP.patch, endpoint; options...)

gh_get_json(endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_get(endpoint; options...), String))
gh_post_json(endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_post(endpoint; options...), String))
gh_put_json(endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_put(endpoint; options...), String))
gh_delete_json(endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_delete(endpoint; options...), String))
gh_patch_json(endpoint = ""; options...) = JSON.parse(HTTP.payload(gh_patch(endpoint; options...), String))

#################
# Rate Limiting #
#################

## There are no rate_limit APIs in GitLab
## rate_limit(; options...) = gh_get_json("/rate_limit"; options...)

##############
# Pagination #
##############

has_page_links(r) = HTTP.hasheader(r, "Link")
get_page_links(r) = split(HTTP.header(r, "Link"), ",")

function find_page_link(links, rel)
    for (i, link) in enumerate(links)
        occursin("rel=\"$rel\"", link) && return i
    end
    return 0
end

extract_page_url(link) = match(r"<.*?>", link).match[2:end-1]

function gitlab_paged_get(endpoint; page_limit = Inf, start_page = "", handle_error = true,
                          headers = Dict(), params = Dict(), options...)
    _headers = convert(Dict{String, String}, headers)
    if !haskey(_headers, "User-Agent")
        _headers["User-Agent"] = "GitLab-jl"
    end
    r = if isempty(start_page)
        gh_get(endpoint; handle_error=handle_error, headers=_headers, params=params, options...)
    else
        @assert isempty(params) "`start_page` kwarg is incompatible with `params` kwarg"
        HTTP.get(start_page, headers=_headers)
    end
    results = HTTP.Response[r]
    page_data = Dict{String,String}()
    if has_page_links(r)
        page_count = 1
        while page_count < page_limit
            links = get_page_links(r)
            next_index = find_page_link(links, "next")
            next_index == 0 && break
            r = HTTP.get(extract_page_url(links[next_index]), headers=_headers)
            handle_error && handle_response_error(r)
            push!(results, r)
            page_count += 1
        end
        links = get_page_links(r)
        for page in ("next", "last", "first", "prev")
            page_index = find_page_link(links, page)
            if page_index != 0
                page_data[page] = extract_page_url(links[page_index])
            end
        end
    end
    return results, page_data
end

function gh_get_paged_json(endpoint = ""; options...)
    results, page_data = gitlab_paged_get(endpoint; options...)
    return mapreduce(r->JSON.parse(HTTP.payload(r, String)), vcat, results), page_data
end

##################
# Error Handling #
##################

function handle_response_error(r::HTTP.Response)
    if r.status >= 400
        message, docs_url, errors = "", "", ""
        body = HTTP.payload(r, String)
        try
            data = JSON.parse(body)
            message = get(data, "message", "")
            docs_url = get(data, "documentation_url", "")
            errors = get(data, "errors", "")
        catch
        end
        err = """
            Error found in GitLab response:
            \tStatus Code: $(r.status)
            """
        if isempty(message) && isempty(errors)
            err *= "\tBody: $body"
        else
            err *= """
                \tMessage: $message
                \tDocs URL: $docs_url
                \tErrors: $errors
                """
        end
        error(err)
    end
end
