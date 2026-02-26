using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using IpPlanet.Application.DTOs.Warehouse;
using IpPlanet.Infrastructure.Data;
using IpPlanet.Application.Interfaces;

namespace IpPlanet.Infrastructure.Service
{
    public class WarehouseService : IWarehouseService
    {
        private readonly DapperContext _context;

        public WarehouseService(DapperContext context)
        {
            _context = context;
        }

        public async Task CreateAsync(CreateWarehouseDto dto)
        {
            const string procedure = "CALL sp_create_warehouse(@p_name, @p_location);";

            using var connection = _context.CreateConnection();

            await connection.ExecuteAsync(procedure, new
            {
                p_name = dto.Name,
                p_location = dto.Location
            });
        }
        }
}