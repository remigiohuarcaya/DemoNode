const express = require("express");
const router = express.Router();
const VendedorController = require("../controllers/vendedor.controller");

// Listar vendedores con opción de búsqueda
router.get("/", VendedorController.listar);

// Formulario de nuevo vendedor
router.get("/nuevo", VendedorController.mostrarFormularioNuevo);

// Crear nuevo vendedor
router.post("/nuevo", VendedorController.crear);

// Formulario de edición
router.get("/editar/:id", VendedorController.mostrarFormularioEditar);

// Actualizar vendedor
router.post("/editar/:id", VendedorController.actualizar);

// Eliminar vendedor (ahora soporta ambos métodos)
router.get("/eliminar/:id", VendedorController.eliminar);

// Exportar rutas 
router.get("/exportar-pdf", VendedorController.exportarPDF);
router.get("/exportar-csv", VendedorController.exportarCSV);

// Ruta alternativa para visualización HTML - nueva función
router.get("/exportar-html", VendedorController.exportarHTML);

// Añadimos rutas alternativas en caso de que haya algún problema con las anteriores
router.get("/pdf", VendedorController.exportarPDF);
router.get("/csv", VendedorController.exportarCSV);

router.delete("/:id", VendedorController.eliminar);

module.exports = router;
