# Movies MCP Server Hosting

This MCP server proxies the Movies API and exposes JSON-RPC methods over HTTP at `/mcp`.

## Project location
- MoviesMcpServer/MoviesMcpServer.csproj

## Configuration
- `MoviesApi:BaseUrl` controls the upstream API base URL.
- Set via `appsettings.json` or environment variable `MoviesApi__BaseUrl`.
- Default local URL: `http://localhost:5010`.

## Run standalone (on-prem VM)
1. Publish the app:
   - `dotnet publish .\MoviesMcpServer\MoviesMcpServer.csproj -c Release -o .\publish\MoviesMcpServer`
2. Configure settings:
   - Edit `publish\MoviesMcpServer\appsettings.json`, or
   - Set environment variables:
     - `MoviesApi__BaseUrl=http://onpremapi.mycontoso.com`
     - `ASPNETCORE_URLS=http://0.0.0.0:5025`
3. Start the server:
   - `dotnet .\publish\MoviesMcpServer\MoviesMcpServer.dll`
4. Test:
   - `GET http://<server>:5025/`
   - `POST http://<server>:5025/mcp`
   - PowerShell (get movies):
     - `Invoke-RestMethod -Method Post -Uri http://<server>:5025/mcp -ContentType "application/json" -Body '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_movies","arguments":{}}}'`

## Run as a Windows Service
### Option A: Framework-dependent (uses dotnet)
1. Publish (same as standalone).
2. Create the service (run in an elevated PowerShell prompt):
   - `sc.exe create MoviesMcpServer binPath= "C:\Program Files\dotnet\dotnet.exe C:\apps\MoviesMcpServer\MoviesMcpServer.dll" start= auto`
3. Set environment variables for the service (either system-wide or via the registry for the service):
   - `MoviesApi__BaseUrl=http://onpremapi.mycontoso.com`
   - `ASPNETCORE_URLS=http://0.0.0.0:5025`
4. Start the service:
   - `sc.exe start MoviesMcpServer`

### Option B: Self-contained executable
1. Publish self-contained:
   - `dotnet publish .\MoviesMcpServer\MoviesMcpServer.csproj -c Release -r win-x64 --self-contained true -o .\publish\MoviesMcpServer`
2. Create the service:
   - `sc.exe create MoviesMcpServer binPath= "C:\apps\MoviesMcpServer\MoviesMcpServer.exe" start= auto`
3. Set environment variables (same as above).
4. Start the service.

## Notes
- Ensure firewall rules allow inbound traffic on the chosen port (default 5025).
- If the Movies API is hosted under an IIS application path (for example, `/MoviesApi`), update the MCP server to call that path or update the Movies API to host at the site root.