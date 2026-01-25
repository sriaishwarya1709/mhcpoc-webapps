using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net.Http.Json;

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
            var movies = await client.GetFromJsonAsync<List<Movie>>("api/movies");
            Movies = movies ?? new List<Movie>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch movies from the API.");
            FriendlyMessage = $"Unable to reach movies service right now. Please try again later.{Environment.NewLine}Service URL: {client.BaseAddress}{Environment.NewLine}Details: {ex.Message}";
        }
    }

    public record Movie(int Id, string Name, string Studio, string Director);
}
