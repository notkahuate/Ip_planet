using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Application.DTOs.Categories;

namespace IpPlanet.Application.Interfaces
{
    public interface ICategoryService
    {
        Task CreateAsync(CreateCategoryDto dto);
    }
}