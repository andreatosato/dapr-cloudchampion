using System;

namespace CloudChampion.Web.ViewModels
{
    /// <summary>
    /// Event
    /// </summary>
    public record OrderEvent(Guid OrderId, OrderStatus OrderStatus);
}
