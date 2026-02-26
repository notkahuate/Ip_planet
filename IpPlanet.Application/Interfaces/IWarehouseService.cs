using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Application.DTOs.Warehouse;

namespace IpPlanet.Application.Interfaces
{
    public interface IWarehouseService
    {
        Task CreateAsync(CreateWarehouseDto dto);
    }
}