using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Items
{
    public class ItemResponseDto
    {
        public Guid Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public string SKU { get; set; } = string.Empty;

        public decimal Price { get; set; }

        public string Category { get; set; } = string.Empty;
    }
}