using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace CloudChampion.Order.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly ILogger<OrderController> _logger;
        private readonly DaprClient daprClient;
        private string orderKey(Guid orderId) => $"OrderProcessing-{orderId}";
        private const string stateManagmentName = "state-managment";

        public OrderController(ILogger<OrderController> logger, DaprClient daprClient)
        {
            this._logger = logger;
            this.daprClient = daprClient;
        }

        [HttpPost]
        public async Task<IActionResult> Post(Order orderToInsert)
        {
            var orderInserting = orderToInsert with { CreatedDate = DateTime.UtcNow };
            // Save State
            var stateOption = new StateOptions { Concurrency = ConcurrencyMode.FirstWrite };
            await daprClient.SaveStateAsync(stateManagmentName, orderKey(orderInserting.OrderId), orderInserting, stateOption);
            // Notify Created State
            await NotifyOrderStatus(orderInserting.OrderId, OrderStatus.Created);

            // Implement logic with timer
            await LogicAsync(orderInserting.OrderId);

            // Notify Completed State
            var orderInserted = orderInserting with { OrderStatus = OrderStatus.Completed };
            var @event = new OrderEvent(orderInserted.OrderId, orderInserted.OrderStatus);
            await daprClient.PublishEventAsync("pubsub", "orderprocessed", @event, HttpContext.RequestAborted);

            // Save State
            await daprClient.SaveStateAsync(stateManagmentName, orderKey(orderInserted.OrderId), orderInserted, stateOption);
            return Ok();
        }

        [HttpGet("{orderId}")]
        public async Task<IActionResult> Get(string orderId)
        {
            var currentStatus = await daprClient.GetStateAsync<Order>(stateManagmentName, orderKey(Guid.Parse(orderId)), ConsistencyMode.Strong);
            return Ok(currentStatus);
        }

        private async Task NotifyOrderStatus(Guid orderId, OrderStatus status)
        {
            var @event = new OrderEvent(orderId, status);
            await daprClient.PublishEventAsync("pubsub", "orderstatus", (dynamic)@event, HttpContext.RequestAborted);
        }

        private async Task LogicAsync(Guid orderId)
        {
            await Task.Delay(3_000);
            await NotifyOrderStatus(orderId, OrderStatus.ProcessingAvailabilityInStock);
            await Task.Delay(10_000);
            await NotifyOrderStatus(orderId, OrderStatus.ProcessingOrderConfirmation);
            await Task.Delay(3_000);
            await NotifyOrderStatus(orderId, OrderStatus.ProcessingPlanShipping);
            await Task.Delay(7_000);
            await NotifyOrderStatus(orderId, OrderStatus.ProcessingNotification);
            await Task.Delay(4_000);
        }
    }
}
