const db = require("../config/db");

class VendedorModel {
  static async listarTodos() {
    const [rows] = await db.query("CALL sp_lisven()");
    return rows[0];
  }

  static async buscarPor(busqueda, tipo) {
    let rows;
    try {
      switch (tipo) {
        case "id":
          [rows] = await db.query("CALL sp_busven(?)", [busqueda]);
          break;
        case "nombre":
        case "apellido":
          [rows] = await db.query("CALL sp_searchven(?)", [busqueda]);
          break;
        default:
          [rows] = await db.query("CALL sp_lisven()");
      }
      return rows[0] || []; // Aseguramos que siempre devuelva al menos un array vacío
    } catch (error) {
      console.error("Error en buscarPor:", error);
      return []; // Devolvemos un array vacío en caso de error
    }
  }

  static async listarDistritos() {
    const [rows] = await db.query("CALL sp_lisdistritos()");
    return rows[0];
  }

  static async listarEspecialidades() {
    const [rows] = await db.query("CALL sp_lisespecialidades()");
    return rows[0];
  }

  static async buscarPorId(id) {
    try {
      const [rows] = await db.query("CALL sp_busven(?)", [id]);
      return rows[0] || []; // Aseguramos que siempre devuelva al menos un array vacío
    } catch (error) {
      console.error("Error en buscarPorId:", error);
      return []; // Devolvemos un array vacío en caso de error
    }
  }

  static async crear(nom_ven, ape_ven, cel_ven, id_distrito, id_esp) {
    const [result] = await db.query("CALL sp_ingven(?, ?, ?, ?,?)", [
      nom_ven,
      ape_ven,
      cel_ven,
      id_distrito,
      id_esp,
    ]);
    return result[0];
  }

  static async actualizar(id_ven, nom_ven, ape_ven, cel_ven, id_distrito, id_esp) {
    return await db.query("CALL sp_modven(?, ?, ?, ?, ?, ?)", [
      id_ven,
      nom_ven,
      ape_ven,
      cel_ven,
      id_distrito,
      id_esp,
    ]);
  }


 static async listarPaginado(limite, offset) {
  try {
    // Si tu base de datos permite procedimientos almacenados con parámetros para límite y offset:
    const [rows] = await db.query("CALL sp_lisven_paginado(?, ?)", [limite, offset]);
    return rows[0];
    
    // Alternativa si no tienes un procedimiento almacenado para paginación:
    // const [rows] = await db.query("SELECT v.*, d.nom_distrito as distrito FROM vendedor v JOIN distrito d ON v.id_distrito = d.id_distrito LIMIT ? OFFSET ?", [limite, offset]);
    // return rows;
  } catch (error) {
    console.error("Error en listarPaginado:", error);
    return [];
  }
}

static async contarTodos() {
  try {
    // También necesitamos saber el total de registros para calcular páginas
    const [rows] = await db.query("SELECT COUNT(*) as total FROM Vendedor");
    return rows[0].total;
  } catch (error) {
    console.error("Error en contarTodos:", error);
    return 0;
  }
}

// Si necesitas paginación en búsquedas también
static async buscarPorPaginado(busqueda, tipo, limite, offset) {
  let rows;
  try {
    switch (tipo) {
      case "id":
        [rows] = await db.query("CALL sp_busven_paginado(?, ?, ?)", [busqueda, limite, offset]);
        break;
      case "nombre":
      case "apellido":
        [rows] = await db.query("CALL sp_searchven_paginado(?, ?, ?)", [busqueda, limite, offset]);
        break;
      default:
        return await this.listarPaginado(limite, offset);
    }
    return rows[0] || [];
  } catch (error) {
    console.error("Error en buscarPorPaginado:", error);
    return [];
  }
}

static async contarFiltrados(busqueda, tipo) {
  try {
    let sql;
    switch (tipo) {
      case "id":
        sql = "SELECT COUNT(*) as total FROM Vendedor WHERE id_ven = ?";
        break;
      case "nombre":
        sql = "SELECT COUNT(*) as total FROM Vendedor WHERE nom_ven LIKE ?";
        busqueda = `%${busqueda}%`;
        break;
      case "apellido":
        sql = "SELECT COUNT(*) as total FROM Vendedor WHERE ape_ven LIKE ?";
        busqueda = `%${busqueda}%`;
        break;
      default:
        return await this.contarTodos();
    }
    const [rows] = await db.query(sql, [busqueda]);
    return rows[0].total;
  } catch (error) {
    console.error("Error en contarFiltrados:", error);
    return 0;
  }
}

  static async eliminar(id_ven) {
    return await db.query("CALL sp_delven(?)", [id_ven]);
  }

}

module.exports = VendedorModel;
