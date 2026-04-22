using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services.Recommendations;

public sealed class RecommendationQueryService : IRecommendationQueryService
{
    public const int RecentOrderWindowDays = 30;

    private readonly IProductRepository _productRepository;
    private readonly IOrderRepository _orderRepository;

    public RecommendationQueryService(
        IProductRepository productRepository,
        IOrderRepository orderRepository)
    {
        _productRepository = productRepository;
        _orderRepository = orderRepository;
    }

    public async Task<RecommendationQueryContext?> BuildAsync(
        Guid customerUserId,
        string? preference,
        CancellationToken cancellationToken)
    {
        if (customerUserId == Guid.Empty)
        {
            return null;
        }

        var catalog = await _productRepository.GetAvailableCatalogAsync(cancellationToken);
        if (catalog.Count == 0)
        {
            return new RecommendationQueryContext(
                catalog,
                new Dictionary<Guid, IReadOnlyList<MenuItem>>(),
                new MenuItemOrderStatistics(
                    new Dictionary<Guid, int>(),
                    new Dictionary<Guid, int>(),
                    new Dictionary<Guid, int>(),
                    new Dictionary<Guid, DateTime>(),
                    false),
                0,
                RecommendationScoringService.ParsePreference(preference),
                GetIstanbulNow(),
                false);
        }

        var menusByRestaurant = catalog
            .GroupBy(c => c.Item.RestaurantId)
            .ToDictionary(
                g => g.Key,
                g => (IReadOnlyList<MenuItem>)g
                    .Select(x => x.Item)
                    .GroupBy(m => m.MenuItemId)
                    .Select(x => x.First())
                    .ToList());

        var stats = await _orderRepository.GetOrderStatisticsAsync(
            customerUserId,
            menusByRestaurant,
            RecentOrderWindowDays,
            cancellationToken);

        var maxGlobal = stats.GlobalQtyByMenuItemId.Values.DefaultIfEmpty(0).Max();

        return new RecommendationQueryContext(
            catalog,
            menusByRestaurant,
            stats,
            maxGlobal,
            RecommendationScoringService.ParsePreference(preference),
            GetIstanbulNow(),
            stats.CustomerHasDeliveredOrders);
    }

    private static DateTime GetIstanbulNow()
    {
        try
        {
            var tz = TimeZoneInfo.FindSystemTimeZoneById(
                OperatingSystem.IsWindows() ? "Turkey Standard Time" : "Europe/Istanbul");
            return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
        }
        catch
        {
            return DateTime.UtcNow;
        }
    }
}
