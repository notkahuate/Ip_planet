using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Warehouse
{
    public class CreateWarehouseDto
    {
        public string Name { get; set; } = string.Empty;

        public string Location { get; set; } = string.Empty;
    }
}   