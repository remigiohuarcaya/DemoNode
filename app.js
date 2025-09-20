// Ejemplo de cómo debería estar configurado tu archivo app.js o server.js
const express = require("express");
const path = require("path"); //path viene instalado con node.js | Maneja las rutas
const app = express();

// Configuraciones
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "public"))); // public puede contener imagenes, css 

// Importar rutas
const vendedoresRoutes = require("./routes/vendedores");

// Registrar rutas
app.use("/vendedores", vendedoresRoutes);

// Ruta para la página principal
app.get("/", (req, res) => {
  res.redirect("/vendedores");
});

// Manejo de errores 404
app.use((req, res, next) => {
  res.status(404).send("Página no encontrada");
});

// Iniciar el servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});

module.exports = app;
