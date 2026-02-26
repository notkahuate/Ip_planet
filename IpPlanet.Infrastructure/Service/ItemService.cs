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
            const string procedure = "CALL sp_create_item(@p_name, @p_sku, @p_category_id, @p_unit_price);";

            using var connection = _context.CreateConnection();

            await connection.ExecuteAsync(procedure, new
            {
                p_name = dto.Name,
                p_sku = dto.SKU,
                p_category_id = dto.CategoryId,
                p_unit_price = dto.Price
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