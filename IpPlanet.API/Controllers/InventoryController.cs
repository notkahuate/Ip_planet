using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using IpPlanet.Application.Interfaces;
using IpPlanet.Application.DTOs.Categories;
using IpPlanet.Application.DTOs.Inventory;

namespace IpPlanet.Api.Controllers;
[ApiController]
[Route("api/[controller]")]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _service;

    public InventoryController(IInventoryService service)
    {
        _service = service;
    }

    [HttpPost("entry")]
    public async Task<IActionResult> Entry([FromBody] InventoryEntryDto dto)
    {
        try
        {
            await _service.RegisterEntryAsync(dto);
            return Ok(new { message = "Inventory entry registered successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("exit")]
    public async Task<IActionResult> Exit([FromBody] InventoryExitDto dto)
    {
        try
        {
            await _service.RegisterExitAsync(dto);
            return Ok(new { message = "Inventory exit registered successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("transfer")]
    public async Task<IActionResult> Transfer([FromBody] InventoryTransferDto dto)
    {
        try
        {
            await _service.TransferAsync(dto);
            return Ok(new { message = "Inventory transferred successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}