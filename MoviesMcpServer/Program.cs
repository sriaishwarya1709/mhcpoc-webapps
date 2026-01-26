using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpClient("MoviesApi", client =>
{
    var baseUrl = builder.Configuration["MoviesApi:BaseUrl"];
    if (!string.IsNullOrWhiteSpace(baseUrl))
    {
        client.BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/");
    }
});

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    name = "Movies MCP Server",
    status = "ok"
}));

app.MapPost("/mcp", async (HttpContext httpContext, IHttpClientFactory httpClientFactory) =>
{
    var request = await JsonSerializer.DeserializeAsync<JsonRpcRequest>(httpContext.Request.Body, JsonSerialization.Options);
    if (request is null)
    {
        return Results.Json(JsonRpcResponse.CreateError(null, -32600, "Invalid Request"), JsonSerialization.Options);
    }

    if (!string.Equals(request.Jsonrpc, "2.0", StringComparison.Ordinal))
    {
        return Results.Json(JsonRpcResponse.CreateError(request.Id, -32600, "Invalid Request"), JsonSerialization.Options);
    }

    return request.Method switch
    {
        "tools/list" => Results.Json(JsonRpcResponse.CreateResult(request.Id, new
        {
            tools = new object[]
            {
                new
                {
                    name = "get_movies",
                    description = "Return the list of movies from MoviesApi.",
                    inputSchema = new
                    {
                        type = "object",
                        properties = new { },
                        additionalProperties = false
                    }
                },
                new
                {
                    name = "get_movie_by_id",
                    description = "Return a movie by id from MoviesApi.",
                    inputSchema = new
                    {
                        type = "object",
                        properties = new
                        {
                            id = new { type = "integer" }
                        },
                        required = new[] { "id" },
                        additionalProperties = false
                    }
                }
            }
        }), JsonSerialization.Options),
        "tools/call" => await HandleToolCallAsync(request, httpClientFactory),
        _ => Results.Json(JsonRpcResponse.CreateError(request.Id, -32601, "Method not found"), JsonSerialization.Options)
    };
});

app.Run();

static async Task<IResult> HandleToolCallAsync(JsonRpcRequest request, IHttpClientFactory httpClientFactory)
{
    if (!request.Params.HasValue)
    {
        return Results.Json(JsonRpcResponse.CreateError(request.Id, -32602, "Invalid params"), JsonSerialization.Options);
    }

    var callParams = request.Params.Value.Deserialize<ToolCallParams>(JsonSerialization.Options);
    if (callParams is null || string.IsNullOrWhiteSpace(callParams.Name))
    {
        return Results.Json(JsonRpcResponse.CreateError(request.Id, -32602, "Invalid params"), JsonSerialization.Options);
    }

    return callParams.Name switch
    {
        "get_movies" => await GetMoviesAsync(request.Id, httpClientFactory),
        "get_movie_by_id" => await GetMovieByIdAsync(request.Id, callParams.Arguments, httpClientFactory),
        _ => Results.Json(JsonRpcResponse.CreateError(request.Id, -32601, "Method not found"), JsonSerialization.Options)
    };
}

static async Task<IResult> GetMoviesAsync(JsonElement? requestId, IHttpClientFactory httpClientFactory)
{
    var client = httpClientFactory.CreateClient("MoviesApi");
    if (client.BaseAddress is null)
    {
        return Results.Json(JsonRpcResponse.CreateError(requestId, -32000, "MoviesApi BaseUrl is not configured"), JsonSerialization.Options);
    }

    using var response = await client.GetAsync("api/movies");
    var rawContent = await response.Content.ReadAsStringAsync();

    if (!response.IsSuccessStatusCode)
    {
        return Results.Json(JsonRpcResponse.CreateError(requestId, -32001, $"MoviesApi returned {(int)response.StatusCode}: {response.ReasonPhrase}. {rawContent}"), JsonSerialization.Options);
    }

    var json = JsonSerializer.Deserialize<JsonElement>(rawContent, JsonSerialization.Options);
    return Results.Json(JsonRpcResponse.CreateResult(requestId, json), JsonSerialization.Options);
}

static async Task<IResult> GetMovieByIdAsync(JsonElement? requestId, JsonElement? arguments, IHttpClientFactory httpClientFactory)
{
    if (!arguments.HasValue || !arguments.Value.TryGetProperty("id", out var idElement) || !idElement.TryGetInt32(out var id))
    {
        return Results.Json(JsonRpcResponse.CreateError(requestId, -32602, "Invalid params: id is required"), JsonSerialization.Options);
    }

    var client = httpClientFactory.CreateClient("MoviesApi");
    if (client.BaseAddress is null)
    {
        return Results.Json(JsonRpcResponse.CreateError(requestId, -32000, "MoviesApi BaseUrl is not configured"), JsonSerialization.Options);
    }

    using var response = await client.GetAsync($"api/movies/{id}");
    var rawContent = await response.Content.ReadAsStringAsync();

    if (!response.IsSuccessStatusCode)
    {
        return Results.Json(JsonRpcResponse.CreateError(requestId, -32001, $"MoviesApi returned {(int)response.StatusCode}: {response.ReasonPhrase}. {rawContent}"), JsonSerialization.Options);
    }

    var json = JsonSerializer.Deserialize<JsonElement>(rawContent, JsonSerialization.Options);
    return Results.Json(JsonRpcResponse.CreateResult(requestId, json), JsonSerialization.Options);
}

static class JsonSerialization
{
    public static readonly JsonSerializerOptions Options = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };
}

record JsonRpcRequest(string Jsonrpc, string Method, JsonElement? Params, JsonElement? Id);

record ToolCallParams(string Name, JsonElement? Arguments);

record JsonRpcResponse(JsonElement? Id, JsonElement? Result, JsonRpcError? Error)
{
    public static JsonRpcResponse CreateResult(JsonElement? id, object result)
        => new(id, JsonSerializer.SerializeToElement(result, JsonSerialization.Options), null);

    public static JsonRpcResponse CreateError(JsonElement? id, int code, string message)
        => new(id, null, new JsonRpcError(code, message));
}

record JsonRpcError(int Code, string Message);
