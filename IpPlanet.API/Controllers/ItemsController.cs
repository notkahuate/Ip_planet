using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using IpPlanet.Application.Interfaces;
using IpPlanet.Application.DTOs.Categories;
using IpPlanet.Application.DTOs.Warehouse;
using IpPlanet.Application.DTOs.Items;

namespace IpPlanet.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ItemsController : ControllerBase
{
    private readonly IItemService _itemService;

    public ItemsController(IItemService itemService)
    {
        _itemService = itemService;
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateItem([FromBody] CreateItemDto dto)
    {
        await _itemService.CreateAsync(dto);
        return StatusCode(201, new { message = "Item created" });
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await _itemService.GetAllAsync();
        return Ok(items);
    }
}