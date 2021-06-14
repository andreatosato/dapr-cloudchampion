using CloudChampion.Web.Hubs;
using CloudChampion.Web.ViewModels;
using Dapr;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System;
using System.Threading.Tasks;

namespace CloudChampion.Web.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly IHubContext<NotificationHub> notificationHub;

        public NotificationsController(IHubContext<NotificationHub> notificationHub)
        {
            this.notificationHub = notificationHub ?? throw new ArgumentNullException(nameof(notificationHub));
        }

        [Topic("pubsub", "orderstatus")]
        [HttpPost("orderstatus")]
        public async Task OrderStatus(OrderEvent @event)
        {
            await notificationHub.Clients.All.SendAsync("orderstatus", @event);
        }

        [Topic("pubsub", "orderprocessed")]
        [HttpPost("orderprocessed")]
        public async Task OrderProcessed(OrderEvent @event)
        {
            await notificationHub.Clients.All.SendAsync("orderprocessed", @event);
        }
    }
}
