# syntax=docker/dockerfile:1

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY MoviesUi/MoviesUi.csproj MoviesUi/
RUN dotnet restore MoviesUi/MoviesUi.csproj

# Copy the rest of the source
COPY . .
WORKDIR /src/MoviesUi

# Publish
RUN dotnet publish MoviesUi.csproj -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Azure Container Apps expects the app to listen on port 8080 by default
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "MoviesUi.dll"]
