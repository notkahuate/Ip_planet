using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Application.DTOs.Items;

namespace IpPlanet.Application.Interfaces
{
    public interface IItemService
    {
        Task CreateAsync(CreateItemDto dto);

        Task<IEnumerable<ItemResponseDto>> GetAllAsync();
    }
}