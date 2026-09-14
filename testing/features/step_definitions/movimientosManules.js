const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// Se registra una sola vez y se reutiliza en todos los escenarios
let perfilIdCompartido = null;

// ------------------------------------------------------------------
// GIVEN
// ------------------------------------------------------------------

Given('que la API del backend esta activa y lista para recibir peticiones', async function () {
  const response = await fetch(`${BACKEND_URL}/api/health`);
  if (!response.ok) {
    throw new Error(`El backend no está disponible. Status: ${response.status}`);
  }
});

Given('que el usuario {string} esta registrado y autenticado', async function (nombreCompleto) {
    if (perfilIdCompartido === null) {
        const email = `${nombreCompleto.trim().toLowerCase().replace(/\s+/g, '.')}.${Date.now()}@test.com`;
        const partes = nombreCompleto.trim().split(' ');
        const nombre = partes[0];
        const apellido = partes[1] || 'Apellido';

        const response = await fetch(`${BACKEND_URL}/api/auth/registro`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: email,
                password: 'Password123!',
                usuario: {
                    nombre: nombre,
                    apellido: apellido,
                    dni: Math.floor(Math.random() * 90000000) + 10000000
                }
            })
        });

        if (!response.ok) {
            throw new Error(`No se pudo registrar el usuario de prueba. Status: ${response.status}`);
        }

        const data = await response.json();
        perfilIdCompartido = data.perfilId;
    }

    this.usuarioAutenticado = { token: 'dummy-token' };
    this.perfilId = perfilIdCompartido;
});

Given('que el usuario autenticado desea registrar un egreso manual', function () {
  assert.ok(this.perfilId, 'No hay un perfilId disponible para registrar movimientos');
});

// ------------------------------------------------------------------
// WHEN
// ------------------------------------------------------------------

When('envio una solicitud POST a {string} con los siguientes datos:', async function (endpoint, dataTable) {
  const movimientos = dataTable.hashes();

  const payload = {
    perfilId: this.perfilId,
    movimientos: movimientos
  };

  const response = await fetch(`${BACKEND_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
    },
    body: JSON.stringify(payload)
  });

  this.responseStatus = response.status;

  try {
    this.responseData = await response.json();
  } catch (e) {
    this.responseData = {};
  }
});

When('envio una solicitud POST a {string} con los siguientes datos incompletos:', async function (endpoint, dataTable) {
  const movimientos = dataTable.hashes();

  const payload = {
    perfilId: this.perfilId,
    movimientos: movimientos
  };

  const response = await fetch(`${BACKEND_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
    },
    body: JSON.stringify(payload)
  });

  this.responseStatus = response.status;

  try {
    this.responseData = await response.json();
  } catch (e) {
    this.responseData = {};
  }
});

When('envio una solicitud POST a {string} con los siguientes datos invalidos:', async function (endpoint, dataTable) {
  const movimientos = dataTable.hashes();

  const payload = {
    perfilId: this.perfilId,
    movimientos: movimientos
  };

  const response = await fetch(`${BACKEND_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
    },
    body: JSON.stringify(payload)
  });

  this.responseStatus = response.status;

  try {
    this.responseData = await response.json();
  } catch (e) {
    this.responseData = {};
  }
});

// ------------------------------------------------------------------
// THEN
// ------------------------------------------------------------------

Then('la respuesta debe tener un codigo de estado {int}', function (expectedStatus) {
  assert.strictEqual(
    this.responseStatus,
    expectedStatus,
    `Se esperaba el código HTTP ${expectedStatus} pero el backend retornó ${this.responseStatus}`
  );
});

Then('la respuesta debe contener el mensaje {string}', function (mensajeEsperado) {
  const mensajeObtenido = this.responseData.message;

  assert.strictEqual(
    mensajeObtenido,
    mensajeEsperado,
    `Se esperaba el mensaje "${mensajeEsperado}", pero el backend devolvió "${mensajeObtenido}"`
  );
});

Then('el movimiento debe estar presente en la base de datos con los datos proporcionados', function () {
  assert.ok(
    Array.isArray(this.responseData.data) && this.responseData.data.length > 0,
    'La respuesta no contiene los movimientos creados'
  );
});

Then('el movimiento no debe estar presente en la base de datos', function () {
  assert.ok(
    this.responseStatus >= 400,
    'Se esperaba que el registro fallara y no se guardara ningún movimiento'
  );
});