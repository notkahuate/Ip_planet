using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Inventory
{
    public class InventoryExitDto
    {
        public Guid ItemId { get; set; }
        public Guid WarehouseId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public Guid UserId { get; set; }
        public string? Notes { get; set; }
    }
}