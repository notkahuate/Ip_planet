using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using IpPlanet.Application.Interfaces;
using IpPlanet.Application.DTOs.Categories;
using IpPlanet.Application.DTOs.Warehouse;

namespace IpPlanet.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WarehousesController : ControllerBase
{
    private readonly IWarehouseService _warehouseService;

    public WarehousesController(IWarehouseService warehouseService)
    {
        _warehouseService = warehouseService;
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateWarehouseDto dto)
    {
        await _warehouseService.CreateAsync(dto);
        return StatusCode(201, new { message = "Warehouse created" });
    }
}