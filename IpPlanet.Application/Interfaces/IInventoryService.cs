using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Application.DTOs.Inventory;

namespace IpPlanet.Application.Interfaces
{
    public interface IInventoryService
    {
        Task RegisterEntryAsync(InventoryEntryDto dto);
        Task RegisterExitAsync(InventoryExitDto dto);
        Task TransferAsync(InventoryTransferDto dto);
    }
}