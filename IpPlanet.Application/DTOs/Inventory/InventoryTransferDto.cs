using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Inventory
{
    public class InventoryTransferDto
    {
        public Guid ItemId { get; set; }
        public Guid SourceWarehouseId { get; set; }
        public Guid TargetWarehouseId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public Guid UserId { get; set; }
        public string? Notes { get; set; }
    }
}