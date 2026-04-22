namespace Vaveyla.Api.Models;

public sealed record RecommendationItemDto(
    Guid Id,
    Guid RestaurantId,
    string? RestaurantName,
    string Name,
    string ShortDescription,
    string ImagePath,
    int Price,
    byte SaleUnit,
    double Score);

public sealed record RecommendationsResponse(IReadOnlyList<RecommendationItemDto> Items);
