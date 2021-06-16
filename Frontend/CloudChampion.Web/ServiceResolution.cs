using Microsoft.Extensions.Configuration;
using System;

namespace CloudChampion.Web
{
    public class ServiceResolution
    {
        private readonly IConfiguration configuration;

        public ServiceResolution(IConfiguration configuration)
        {
            this.configuration = configuration;
        }

        public Uri Web => configuration.GetServiceUri("cloudchampion-web");
    }
}
