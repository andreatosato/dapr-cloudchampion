using System;

namespace CloudChampion.Order
{
    public record Order(Guid OrderId, int Quantity, string ProductName, DateTime CreatedDate, OrderStatus OrderStatus);
    public enum OrderStatus
    {
        Created,
        ProcessingAvailabilityInStock,
        ProcessingOrderConfirmation,
        ProcessingPlanShipping,
        ProcessingNotification,
        Completed
    }

    public record OrderEvent(Guid OrderId, OrderStatus OrderStatus);
}
