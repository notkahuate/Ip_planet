using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using IpPlanet.Application.DTOs.Inventory;
using IpPlanet.Application.Interfaces;
using IpPlanet.Infrastructure.Data;

namespace IpPlanet.Infrastructure.Service
{
    public class InventoryService : IInventoryService
    {
        private readonly DapperContext _context;

    public InventoryService(DapperContext context)
    {
        _context = context;
    }

    public async Task RegisterEntryAsync(InventoryEntryDto dto)
    {
        const string procedure = "CALL sp_register_inventory_entry(@ItemId, @WarehouseId, @Quantity, @UnitPrice, @UserId, @Notes);";
        using var connection = _context.CreateConnection();
        await connection.ExecuteAsync(procedure, dto);
    }

    public async Task RegisterExitAsync(InventoryExitDto dto)
    {
        const string procedure = "CALL sp_register_inventory_exit(@ItemId, @WarehouseId, @Quantity, @UnitPrice, @UserId, @Notes);";
        using var connection = _context.CreateConnection();
        await connection.ExecuteAsync(procedure, dto);
    }

    public async Task TransferAsync(InventoryTransferDto dto)
    {
        const string procedure = "CALL sp_transfer_inventory(@ItemId, @SourceWarehouseId, @TargetWarehouseId, @Quantity, @UnitPrice, @UserId, @Notes);";
        using var connection = _context.CreateConnection();
        await connection.ExecuteAsync(procedure, dto);
    }
    }
}