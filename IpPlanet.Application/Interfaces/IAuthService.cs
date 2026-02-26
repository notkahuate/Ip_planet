using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using IpPlanet.Application.DTOs.Auth;

namespace IpPlanet.Application.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponseDto?> LoginAsync(LoginRequestDto request);
        Task RegisterAsync(RegisterUserDTo dto);
    }
}