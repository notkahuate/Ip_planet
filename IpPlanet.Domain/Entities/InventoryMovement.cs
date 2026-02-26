using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Domain.Entities
{
    public class InventoryMovement
    {
        public Guid Id { get; set; }

        public string ItemName { get; set; } = string.Empty;

        public string WarehouseName { get; set; } = string.Empty;

        public string MovementType { get; set; } = string.Empty;

        public int Quantity { get; set; }

        public string PerformedBy { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; }
    }
}