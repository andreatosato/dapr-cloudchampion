using System;

namespace CloudChampion.Web.ViewModels
{
    public class InsertOrderViewModel
    {
        public Guid OrderId { get; set; }
        public int Quantity { get; set; }
        public string ProductName { get; set; }
    }

    public class StatusOrderViewModel : InsertOrderViewModel
    {
        public DateTime CreatedDate { get; set; }
        public OrderStatus OrderStatus { get; set; }
    }

    public enum OrderStatus
    {
        Created,
        ProcessingAvailabilityInStock,
        ProcessingOrderConfirmation,
        ProcessingPlanShipping,
        ProcessingNotification,
        Completed
    }
}
