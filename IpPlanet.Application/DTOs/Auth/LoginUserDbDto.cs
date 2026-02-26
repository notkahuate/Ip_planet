using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace IpPlanet.Application.DTOs.Auth
{
    public class LoginUserDbDto
    {
        public Guid Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password_Hash { get; set; } = string.Empty;
        
        public string Role_Name { get; set; } = string.Empty;
    }
}