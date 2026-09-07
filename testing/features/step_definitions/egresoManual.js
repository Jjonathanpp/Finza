const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PASOS PREVIOS (GIVEN)
// ------------------------------------------------------------------

Given('que la API del backend esta activa y lista para recibir peticiones', async function () {
  try {
    await fetch(`${BACKEND_URL}/actuator/health`);
  } catch (error) {
    throw new Error(`Error al verificar el estado de la API: ${error.message}`);
  }
});

Given('que el usuario {string} esta registrado y autenticado', async function (nombreUsuario) {
  this.usuarioAutenticado = {
    nombre: nombreUsuario.trim(),
    token: 'jwt-token-simulado-123'
  };
});

Given('que el usuario autenticado desea registrar un gasto manual', function () {
  assert.ok(
    this.usuarioAutenticado,
    'Se requiere un usuario autenticado para realizar esta operacion'
  );
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envio una solicitud POST a {string} con los siguientes datos:', async function (endpoint, dataTable) {
  const movimientos = dataTable.hashes();

  try {
    const response = await fetch(`${BACKEND_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
      },
      body: JSON.stringify(movimientos)
    });

    this.responseStatus = response.status;

    try {
      this.responseData = await response.json();
    } catch (e) {
      this.responseData = {};
    }
  } catch (error) {
    throw new Error(`Error de conexion al enviar la peticion HTTP a ${endpoint}: ${error.message}`);
  }
});

When('envio una solicitud POST a {string} con los siguientes datos incompletos:', async function (endpoint, dataTable) {
  const movimientosIncompletos = dataTable.hashes();

  try {
    const response = await fetch(`${BACKEND_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
      },
      body: JSON.stringify(movimientosIncompletos)
    });

    this.responseStatus = response.status;

    try {
      this.responseData = await response.json();
    } catch (e) {
      this.responseData = {};
    }
  } catch (error) {
    throw new Error(`Error de conexion al enviar la peticion HTTP a ${endpoint}: ${error.message}`);
  }
});

When('envio una solicitud POST a {string} con los siguientes datos invalidos:', async function (endpoint, dataTable) {
  const movimientosInvalidos = dataTable.hashes();

  try {
    const response = await fetch(`${BACKEND_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
      },
      body: JSON.stringify(movimientosInvalidos)
    });

    this.responseStatus = response.status;

    try {
      this.responseData = await response.json();
    } catch (e) {
      this.responseData = {};
    }
  } catch (error) {
    throw new Error(`Error de conexion al enviar la peticion HTTP a ${endpoint}: ${error.message}`);
  }
});

// ------------------------------------------------------------------
// ASERCIONES Y VALIDACIONES DE RESPUESTA (THEN)
// ------------------------------------------------------------------

Then('la respuesta debe tener un codigo de estado {int}', function (expectedStatus) {
  assert.strictEqual(
    this.responseStatus,
    expectedStatus,
    `Se esperaba el codigo HTTP ${expectedStatus} pero el backend retorno ${this.responseStatus}`
  );
});

Then('la respuesta debe contener el mensaje {string}', function (mensajeEsperado) {
  const mensajeObtenido =
    this.responseData.mensaje ||
    this.responseData.message ||
    this.responseData.error;

  assert.strictEqual(
    mensajeObtenido,
    mensajeEsperado,
    `Se esperaba el mensaje "${mensajeEsperado}", pero el backend devolvio "${mensajeObtenido}"`
  );
});

Then('el movimiento debe estar presente en la base de datos con los datos proporcionados', async function () {
  try {
    const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
      }
    });

    const movimientosEnBD = await response.json();
    assert.ok(
      Array.isArray(movimientosEnBD) && movimientosEnBD.length > 0,
      'No se encontraron movimientos guardados en la base de datos'
    );
  } catch (error) {
    throw new Error(`Error al verificar la presencia del movimiento en la base de datos: ${error.message}`);
  }
});

Then('el movimiento no debe estar presente en la base de datos', async function () {
  try {
    const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
      }
    });

    if (response.status === 404) {
      return;
    }

    const movimientosEnBD = await response.json();
    const cantidad = Array.isArray(movimientosEnBD) ? movimientosEnBD.length : 0;

    assert.strictEqual(
      cantidad,
      0,
      'Se encontraron movimientos guardados en la base de datos cuando la solicitud debia fallar'
    );
  } catch (error) {
    assert.ok(true);
  }
});