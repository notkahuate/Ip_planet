using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using IpPlanet.Application.DTOs.Auth;
using IpPlanet.Application.Interfaces;
using IpPlanet.Infrastructure.Data;

namespace IpPlanet.Infrastructure.Service
{
    public class AuthService : IAuthService
    {
        private readonly DapperContext _context;

        public AuthService(DapperContext context)
        {
            _context = context;
        }

        public async Task<LoginResponseDto?> LoginAsync(LoginRequestDto request)
        {
            const string query = "SELECT * FROM fn_get_user_for_login(@Username);";

            using var connection = _context.CreateConnection();

            var user = await connection.QuerySingleOrDefault<dynamic>(
                query,
                new { Username = request.Username });

            if (user == null)
                return null;

            bool isValid = BCrypt.Net.BCrypt.Verify(request.Password, (string)user.password_hash);

            if (!isValid)
                return null;

            return new LoginResponseDto
            {
                Id = user.id,
                Username = user.username,
                Role = user.role_name
            };
        }
        }
}