using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net.Http.Json;
using System.Text.Json;

namespace MoviesUi.Pages;

public class IndexModel : PageModel
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<IndexModel> _logger;

    public IndexModel(IHttpClientFactory httpClientFactory, ILogger<IndexModel> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public IReadOnlyList<Movie> Movies { get; private set; } = Array.Empty<Movie>();
    public string? FriendlyMessage { get; private set; }
    public string? RequestUrl { get; private set; }

    public async Task OnGetAsync()
    {
        var client = _httpClientFactory.CreateClient("MoviesApi");
        if (client.BaseAddress is null)
        {
            FriendlyMessage = "Movies service URL is not configured.";
            return;
        }

        try
        {
            using var response = await client.GetAsync("MoviesApi/api/movies");
            var rawContent = await response.Content.ReadAsStringAsync();
            var requestInfo = response.RequestMessage is null
                ? "Request: <unknown>"
                : $"Request: {response.RequestMessage.Method} {response.RequestMessage.RequestUri}";
            RequestUrl = response.RequestMessage?.RequestUri?.ToString();

            if (!response.IsSuccessStatusCode)
            {
                FriendlyMessage = $"Movies service returned {(int)response.StatusCode} ({response.ReasonPhrase}).{Environment.NewLine}{requestInfo}{Environment.NewLine}Service URL: {client.BaseAddress}{Environment.NewLine}Response: {rawContent}";
                return;
            }

            var movies = JsonSerializer.Deserialize<List<Movie>>(rawContent, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            Movies = movies ?? new List<Movie>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch movies from the API.");
            FriendlyMessage = $"Unable to reach movies service right now. Please try again later.{Environment.NewLine}Request: GET {client.BaseAddress}api/movies{Environment.NewLine}Service URL: {client.BaseAddress}{Environment.NewLine}Details: {ex.Message}";
        }
    }

    public record Movie(int Id, string Name, string Studio, string Director);
}
