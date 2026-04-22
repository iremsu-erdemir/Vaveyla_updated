using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services.Recommendations;

public sealed class RecommendationComposer : IRecommendationComposer
{
    public RecommendationsResponse Compose(
        RecommendationQueryContext context,
        IReadOnlyList<(RecommendationCatalogRow Row, double Score)> scored)
    {
        var orderedRows = scored
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x =>
                context.Statistics.GlobalQtyByMenuItemId.GetValueOrDefault(x.Row.Item.MenuItemId))
            .Select(x => x.Row)
            .DistinctBy(x => x.Item.MenuItemId)
            .ToList();

        var n = orderedRows.Count;
        var pickCount = n == 0 ? 0 : n < 3 ? n : Math.Min(5, n);

        var scoreByMenuItemId = scored
            .GroupBy(x => x.Row.Item.MenuItemId)
            .ToDictionary(g => g.Key, g => g.Max(x => x.Score));

        var picked = orderedRows.Take(pickCount).ToList();

        var items = picked
            .Select(row =>
            {
                scoreByMenuItemId.TryGetValue(row.Item.MenuItemId, out var s);
                return new RecommendationItemDto(
                    row.Item.MenuItemId,
                    row.Item.RestaurantId,
                    row.RestaurantName,
                    row.Item.Name,
                    BuildShortDescription(row),
                    row.Item.ImagePath,
                    row.Item.Price,
                    row.Item.SaleUnit,
                    Math.Round(s, 4));
            })
            .ToList();

        return new RecommendationsResponse(items);
    }

    private static string BuildShortDescription(RecommendationCatalogRow row)
    {
        var cat = string.IsNullOrWhiteSpace(row.Item.CategoryName) ? "Tatlı" : row.Item.CategoryName!.Trim();
        var rest = string.IsNullOrWhiteSpace(row.RestaurantName) ? "Pastane" : row.RestaurantName.Trim();
        var text = $"{cat} · {rest}";
        return text.Length <= 140 ? text : text[..137] + "...";
    }
}
