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

        public async Task RegisterAsync(RegisterUserDTo dto)
{
            const string procedure = "CALL sp_create_user(@Username, @Email, @PasswordHash, @RoleId);";

            using var connection = _context.CreateConnection();

            // Encriptar contraseña antes de guardar
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);

            await connection.ExecuteAsync(procedure, new
            {
                dto.Username,
                dto.Email,
                PasswordHash = passwordHash,
                dto.RoleId
            });
        }

        public async Task<LoginResponseDto?> LoginAsync(LoginRequestDto request)
{
            const string query = "SELECT * FROM fn_get_user_for_login(@Username);";

            using var connection = _context.CreateConnection();

            var user = await connection.QuerySingleOrDefaultAsync<LoginUserDbDto>(
                query,
                new { Username = request.Username });

            if (user == null)
                return null;

            bool isValid = BCrypt.Net.BCrypt.Verify(request.Password, user.Password_Hash);

            if (!isValid)
                return null;

            return new LoginResponseDto
            {
                Id = user.Id,
                Username = user.Username,
                Role = user.Role_Name,
                Email = user.Email
            };
        }
    }
}