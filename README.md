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

## Deploy MoviesApi to IIS
Use this to host the API on Windows Server with IIS.

### Prerequisites
1. Install the .NET 10 Hosting Bundle (ASP.NET Core Runtime + IIS integration) on the server.
2. Ensure the Windows Server has IIS with the **ASP.NET Core Module** enabled (installed by the Hosting Bundle).

### Publish the API
From the repo root, publish to a folder:
1. `dotnet publish .\MoviesApi\MoviesApi.csproj -c Release -o .\publish\MoviesApi`

### Configure IIS
1. Copy the published output folder (for example, `publish\MoviesApi`) to the server.
2. Open **IIS Manager**.
3. Create or select an Application Pool:
   - **.NET CLR version**: *No Managed Code*
   - **Pipeline mode**: *Integrated*
4. Create a new website (or application) and point **Physical path** to the published folder, name the application MoviesApi.
5. Assign the site to the Application Pool you configured.
6. (Optional) Add environment variables in IIS if needed:
   - `ASPNETCORE_ENVIRONMENT` (for example, `Production`)
7. (Optional) To host at the site root, set the **Default Web Site** Physical Path to the published folder and remove any MoviesApi application.
8. Start the site and browse to `http://<server>/MoviesApi/api/movies` to validate the response (or `http://<server>/api/movies` if hosted at root).

### Notes
- HTTPS redirection is currently commented out in the API. You can run HTTP-only on IIS, but HTTPS is recommended for production.
- To enable HTTPS, add an HTTPS binding with a valid certificate in IIS and uncomment `app.UseHttpsRedirection()` in `MoviesApi/Program.cs`.
- If you need a different base URL for the UI, update `MoviesApi:BaseUrl` in the UI config (see Configuration section above).
