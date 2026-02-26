using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Npgsql;

namespace IpPlanet.Infrastructure.Data
{
    public class DapperContext
    {
       private readonly string _connectionString;

        public DapperContext()
        {
            var host = Environment.GetEnvironmentVariable("DB_HOST");
            var port = Environment.GetEnvironmentVariable("DB_PORT");
            var db = Environment.GetEnvironmentVariable("DB_NAME");
            var user = Environment.GetEnvironmentVariable("DB_USER");
            var pass = Environment.GetEnvironmentVariable("DB_PASSWORD");

            _connectionString =
                $"Host={host};Port={port};Database={db};Username={user};Password={pass}";
        }

        public IDbConnection CreateConnection()
            => new NpgsqlConnection(_connectionString);
    }
}