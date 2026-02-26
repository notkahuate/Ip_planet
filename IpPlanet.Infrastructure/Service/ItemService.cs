using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Infrastructure.Data;
using IpPlanet.Application.Interfaces;
using IpPlanet.Application.DTOs.Items;
using Dapper;

namespace IpPlanet.Infrastructure.Service
{
    public class ItemService : IItemService
    {
        private readonly DapperContext _context;

        public ItemService(DapperContext context)
        {
            _context = context;
        }

        public async Task CreateAsync(CreateItemDto dto)
        {
            const string procedure = "CALL sp_create_item(@Name, @SKU, @Price, @CategoryId);";

            using var connection = _context.CreateConnection();

            await connection.ExecuteAsync(procedure, new
            {
                dto.Name,
                dto.SKU,
                dto.Price,
                dto.CategoryId
            });
        }

        public async Task<IEnumerable<ItemResponseDto>> GetAllAsync()
        {
            const string query = "SELECT * FROM fn_get_items();";

            using var connection = _context.CreateConnection();

            var items = await connection.QueryAsync<ItemResponseDto>(query);

            return items;
        }
        }
}