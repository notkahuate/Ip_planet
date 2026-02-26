# 🪐 IpPlanet API

API desarrollada en **.NET 9** con **C#**, utilizando **Dapper**, **PostgreSQL**, **JWT Authentication** y **Swagger** para la gestión de inventarios, categorías, items y almacenes.  

---

## 💡 Idea del proyecto

IpPlanet es una API de gestión de inventarios que permite:

- Registrar usuarios y autenticarlos con JWT.
- Administrar categorías de productos.
- Crear y listar items de inventario.
- Crear y listar almacenes.
- Asignar roles a los usuarios (`Admin` y `User`) y proteger endpoints según permisos.

El proyecto está pensado para que **solo los usuarios con rol Admin** puedan crear categorías, items o almacenes, mientras que cualquier usuario autenticado puede listar información.

---

## 📦 Tecnologías usadas

- .NET 9
- C#
- Dapper
- PostgreSQL
- JWT para autenticación y autorización
- Swagger para documentación interactiva
- DotNetEnv para variables de entorno

---

## 🔧 Estructura del proyecto

Clean Architecture implemtando diferetnes capas como Domain, Applicatio y infrastructure


## Como correr el Proyecto

1. clone el repositorio
    git clone https://github.com/notkahuate/Ip_planet
    cd IpPlanet
2. instale dependencias 
    dotnet restore
    dotnet build
3. Cree la base de datos 
    Puede copiarla y pegar se encuentra en el archivo BD.sql
4. Ejecute el proyecto en consola 
   dotnet run --project IpPlanet.Api
5. Puede abrir swagger 
    http://localhost:5171/swagger/index.html

## Modelo relacional de la base de datos 
   