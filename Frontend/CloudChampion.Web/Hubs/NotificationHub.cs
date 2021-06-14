using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace CloudChampion.Web.Hubs
{
    public class NotificationHub : Hub
    {
        public override Task OnConnectedAsync()
        {
            return base.OnConnectedAsync();
        }
    }
}
