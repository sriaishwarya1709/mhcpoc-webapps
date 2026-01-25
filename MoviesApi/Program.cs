using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// app.UseHttpsRedirection();

var moviesJson = """
[
  { "id": 1, "name": "Echoes of Tomorrow", "studio": "Northwind Studios", "director": "Ava Sterling" },
  { "id": 2, "name": "Crimson Harbor", "studio": "Silverlight Pictures", "director": "Miles Bennett" },
  { "id": 3, "name": "The Glass Orchard", "studio": "Contoso Films", "director": "Sienna Park" },
  { "id": 4, "name": "Midnight Atlas", "studio": "Fabrikam Entertainment", "director": "Noah Reed" },
    { "id": 5, "name": "Rising Ember", "studio": "Tailspin Media", "director": "Priya Desai" },
    { "id": 6, "name": "Velvet Horizon", "studio": "Woodgrove Productions", "director": "Elena Cruz" },
    { "id": 7, "name": "Signal in the Pines", "studio": "Fourth Coffee Films", "director": "Jonah Lake" },
    { "id": 8, "name": "Ironwood Sky", "studio": "Blue Yonder Studios", "director": "Camila Ortiz" },
    { "id": 9, "name": "Paper Constellations", "studio": "Lucerne Pictures", "director": "Darius Cole" },
    { "id": 10, "name": "Saffron Tide", "studio": "Sunrise Gate Media", "director": "Maya Rao" }
]
""";

var movies = JsonSerializer.Deserialize<List<Movie>>(moviesJson, new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true
}) ?? new List<Movie>();

app.MapGet("/api/movies", () => Results.Ok(movies))
    .WithName("GetMovies");

app.MapGet("/api/movies/{id:int}", (int id) =>
    movies.FirstOrDefault(movie => movie.Id == id) is { } found
        ? Results.Ok(found)
        : Results.NotFound())
    .WithName("GetMovieById");

app.Run();

record Movie(int Id, string Name, string Studio, string Director);
