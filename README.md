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
1. Copy the published output folder (for example, `publish\MoviesApi`) to the server (eg, `c:\inetpub\wwwroot\MoviesApi`).
2. Open **IIS Manager**.
3. Create or select an Application Pool:
   - **.NET CLR version**: *No Managed Code*
   - **Pipeline mode**: *Integrated*
4. Create a new website (or application eg MoviesApi) and point **Physical path** to the published folder, name the application MoviesApi.
5. Assign the site to the Application Pool you configured.
6. (Optional) Add environment variables in IIS if needed:
   - `ASPNETCORE_ENVIRONMENT` (for example, `Production`)
7. (Optional) To host at the site root, set the **Default Web Site** Physical Path to the published folder
8. Start the site and browse to `http://<server>/MoviesApi/api/movies` to validate the response (or `http://<server>/api/movies` if hosted at root).

### Notes
- HTTPS redirection is currently commented out in the API. You can run HTTP-only on IIS, but HTTPS is recommended for production.
- To enable HTTPS, add an HTTPS binding with a valid certificate in IIS and uncomment `app.UseHttpsRedirection()` in `MoviesApi/Program.cs`.
- If you need a different base URL for the UI, update `MoviesApi:BaseUrl` in the UI config (see Configuration section above). The base URL ends at domain name, additional path will be stripped! so only `http://server_dns_name>`

## Configure Private Resolver for App Service to reach on-prem IIS
Use this when the API is hosted on-premises and the UI runs in App Service integrated to a spoke VNet, with Azure DNS Private Resolver in the hub VNet.

### Prerequisites
1. Hub-and-spoke VNets are peered (hub ↔ spoke) with **Allow forwarded traffic** enabled.
2. Connectivity from Azure to on-prem exists (VPN or ExpressRoute).
3. The IIS server has a stable DNS name (for example, `onpremapi.mycontoso.com`) and reachable IP from Azure.

### Steps
1. In the hub VNet, deploy **Azure DNS Private Resolver** with:
   - An **Inbound Endpoint** in a hub subnet.
   - An **Outbound Endpoint** in another hub subnet.
2. Create a **DNS Forwarding Ruleset** and add a rule that forwards your on-prem DNS zone (for example, `mycontoso.com`) to your on-prem DNS servers using the Outbound Endpoint of the Private Resolver
3. Link the ruleset to the **spoke VNet** where the App Service VNet integration subnet lives.
4. Configure conditional forwarder on your **on-prem DNS** servers to forward queries for Azure private zones (if any) to the Private Resolver **Inbound Endpoint** IPs.
5. Ensure NSGs and firewalls allow DNS (UDP/TCP 53) between spoke ↔ hub and hub ↔ on-prem.
6. Update the Web UI app setting `MoviesApi__BaseUrl` to the on-prem hostname (for example, `http://onpremapi.mycontoso.com`).
7. Validate resolution and connectivity:
   - From the App Service (Kudu/Console), `nslookup onpremapi.mycontoso.com` should return the on-prem IP.
   - Access `http://onpremapi.mycontoso.com/MoviesApi/api/movies` (or `/api/movies` if hosted at IIS Server root).
