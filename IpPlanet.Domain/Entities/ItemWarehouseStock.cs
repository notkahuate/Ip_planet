using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Domain.Entities
{
    public class ItemWarehouseStock
    {
        public Guid ItemId { get; set; }

        public Guid WarehouseId { get; set; }

        public int Quantity { get; set; }
    }
}