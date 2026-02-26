using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using IpPlanet.Application.DTOs.Categories;
using IpPlanet.Infrastructure.Data;
using IpPlanet.Application.Interfaces;

namespace IpPlanet.Infrastructure.Service
{
    public class CategoryService : ICategoryService
    {
        private readonly DapperContext _context;

        public CategoryService(DapperContext context)
        {
            _context = context;
        }

        public async Task CreateAsync(CreateCategoryDto dto)
        {
             const string procedure = "CALL sp_create_category(@category_name, @category_desc);";

             using var connection = _context.CreateConnection();

            await connection.ExecuteAsync(procedure, new
            {
                category_name = dto.Name,
                category_desc = "" 
            });
        }
        }
}