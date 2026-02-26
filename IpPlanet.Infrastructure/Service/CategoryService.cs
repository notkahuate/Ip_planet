using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using IpPlanet.Application.DTOs.Categories;
using IpPlanet.Infrastructure.Data;

namespace IpPlanet.Infrastructure.Service
{
    public class CategoryService
    {
        private readonly DapperContext _context;

        public CategoryService(DapperContext context)
        {
            _context = context;
        }

        public async Task CreateAsync(CreateCategoryDto dto)
        {
            const string procedure = "CALL sp_create_category(@Name);";

            using var connection = _context.CreateConnection();

            await connection.ExecuteAsync(procedure, new
            {
                dto.Name
            });
        }
        }
}