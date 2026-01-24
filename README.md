# Movies Demo

Two .NET apps:
- MoviesApi: ASP.NET Core Web API serving movies.
- MoviesUi: ASP.NET Core Razor Pages UI displaying movies in a table.

## Configuration
MoviesUi reads the API base URL from configuration:
- Setting key: `MoviesApi:BaseUrl`
- App Service setting name: `MoviesApi__BaseUrl`

To configure in Azure App Service:
1. Open the UI App Service (appmhcwebuieus2).
2. Go to Configuration > Application settings.
3. Add a new setting named `MoviesApi__BaseUrl` with the API URL (for example, `https://appmhcapieus2.azurewebsites.net`).
4. Save and restart the UI app.

## Run locally
1. Start the API:
   - `dotnet run --project .\MoviesApi\MoviesApi.csproj`
2. Update `MoviesUi/appsettings.json` to match the API URL if needed.
3. Start the UI:
   - `dotnet run --project .\MoviesUi\MoviesUi.csproj`

## Endpoints
- `GET /api/movies`
- `GET /api/movies/{id}`
