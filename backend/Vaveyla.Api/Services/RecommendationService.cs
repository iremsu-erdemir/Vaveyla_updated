using Microsoft.Extensions.Caching.Memory;
using Vaveyla.Api.Models;
using Vaveyla.Api.Services.Recommendations;

namespace Vaveyla.Api.Services;

public sealed class RecommendationService : IRecommendationService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(90);

    private readonly IMemoryCache _cache;
    private readonly IRecommendationQueryService _query;
    private readonly IRecommendationScoringService _scoring;
    private readonly IRecommendationComposer _composer;

    public RecommendationService(
        IMemoryCache cache,
        IRecommendationQueryService query,
        IRecommendationScoringService scoring,
        IRecommendationComposer composer)
    {
        _cache = cache;
        _query = query;
        _scoring = scoring;
        _composer = composer;
    }

    public async Task<RecommendationsResponse> GetRecommendationsAsync(
        Guid userId,
        string? preference,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return new RecommendationsResponse(Array.Empty<RecommendationItemDto>());
        }

        var prefKey = string.IsNullOrWhiteSpace(preference) ? "any" : preference.Trim().ToLowerInvariant();
        var cacheKey = $"recommendation:{userId:N}:{prefKey}";

        if (_cache.TryGetValue(cacheKey, out RecommendationsResponse? cached) && cached is not null)
        {
            return cached;
        }

        var context = await _query.BuildAsync(userId, preference, cancellationToken);
        if (context is null)
        {
            return new RecommendationsResponse(Array.Empty<RecommendationItemDto>());
        }

        if (context.Catalog.Count == 0)
        {
            var empty = new RecommendationsResponse(Array.Empty<RecommendationItemDto>());
            _cache.Set(cacheKey, empty, CacheDuration);
            return empty;
        }

        var scored = _scoring.ScoreAll(context);
        var result = _composer.Compose(context, scored);

        _cache.Set(cacheKey, result, CacheDuration);
        return result;
    }
}
