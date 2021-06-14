using CloudChampion.Web.ViewModels;
using Dapr.Client;
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace CloudChampion.Web.Services
{
    public class OrderService
    {
        private readonly DaprClient daprClient;
        private readonly string appId = "cloudchampion-order";

        public OrderService(DaprClient daprClient)
        {
            this.daprClient = daprClient;
        }

        public async Task InsertOrder(InsertOrderViewModel order)
        {
            string appMethod = "Order";
            await daprClient.InvokeMethodAsync(appId, appMethod, order);
        }

        public Task<StatusOrderViewModel> GetStatusOrder(Guid orderId)
        {
            string appMethod = $"Order/{orderId}";
            return daprClient.InvokeMethodAsync<StatusOrderViewModel>(HttpMethod.Get, appId, appMethod);
        }
    }
}
