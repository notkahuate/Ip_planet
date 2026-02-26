using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Items
{
    public class CreateItemDto
    {
        public string Name { get; set; } = string.Empty;

        public string SKU { get; set; } = string.Empty;

        public decimal Price { get; set; }

        public Guid CategoryId { get; set; }
    }
}