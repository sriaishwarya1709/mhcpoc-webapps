using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net.Http.Json;

namespace MoviesUi.Pages;

public class IndexModel : PageModel
{
    private readonly IHttpClientFactory _httpClientFactory;

    public IndexModel(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
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
        catch (Exception)
        {
            FriendlyMessage = "Unable to reach movies service right now. Please try again later.";
        }
    }

    public record Movie(int Id, string Name, string Studio, string Director);
}
