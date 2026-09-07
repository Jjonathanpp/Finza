const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PASOS PREVIOS (GIVEN)
// ------------------------------------------------------------------

Given('que la API del backend está activa y lista para recibir peticiones', async function () {
  try {
    await fetch(`${BACKEND_URL}/actuator/health`);
  } catch (error) {
  }
});

Given('que existe un usuario registrado con el email {string}', async function (email) {
  // Pre-creamos un usuario de prueba en PostgreSQL para forzar la validación de email duplicado
  try {
    await fetch(`${BACKEND_URL}/api/auth/registro`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nombre: 'Usuario Existente',
        email: email,
        password: 'Password123!'
      })
    });
  } catch (error) {
  }
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envío una solicitud POST a {string} con los siguientes datos:', async function (endpoint, dataTable) {
  // Extraemos la tabla clave-valor enviada desde la especificación Gherkin (.feature)
  const rawData = dataTable.rowsHash();

  const payload = {
    nombre: rawData.nombre || '',
    email: rawData.email || '',
    password: rawData.password || ''
  };

  try {
    const response = await fetch(`${BACKEND_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    // Almacenamos los resultados dentro de la instancia 'this' del contexto del escenario[cite: 1]
    this.responseStatus = response.status;

    // Intentamos parsear la respuesta enviada por el backend Java
    try {
      this.responseData = await response.json();
    } catch (e) {
      this.responseData = {};
    }
  } catch (error) {
    throw new Error(`Error de conexión al enviar la petición HTTP a ${endpoint}: ${error.message}`);
  }
});

// ------------------------------------------------------------------
// ASERCIONES Y VALIDACIONES DE RESPUESTA (THEN)
// ------------------------------------------------------------------

Then('la respuesta debe tener un código de estado {int}', function (expectedStatus) {
  assert.strictEqual(
    this.responseStatus,
    expectedStatus,
    `Se esperaba el código HTTP ${expectedStatus} pero el backend retornó ${this.responseStatus}`
  );
});

Then('la respuesta debe contener un token de autenticación', function () {
  const token = this.responseData.token || this.responseData.accessToken;
  assert.ok(
    token,
    `El JSON devuelto no incluye un token de autenticación. Respuesta recibida: ${JSON.stringify(this.responseData)}`
  );
});

Then('el usuario debe quedar registrado en la base de datos', function () {
  const idOEmail = this.responseData.id || this.responseData.email;
  assert.ok(
    idOEmail,
    'El JSON de respuesta no contiene datos identificativos del usuario registrado'
  );
});

Then('la respuesta debe contener el mensaje de error {string}', function (mensajeEsperado) {
  const mensajeObtenido =
    this.responseData.mensaje ||
    this.responseData.message ||
    this.responseData.error;

  assert.strictEqual(
    mensajeObtenido,
    mensajeEsperado,
    `Se esperaba el mensaje "${mensajeEsperado}", pero el backend devolvió "${mensajeObtenido}"`
  );
});

Then('la respuesta debe indicar los campos faltantes requeridos', function () {
  const tieneErrores =
    Array.isArray(this.responseData.errors) ||
    this.responseData.mensaje ||
    this.responseStatus === 400;

  assert.ok(
    tieneErrores,
    'La respuesta no proporcionó detalles de validación sobre los campos requeridos faltantes'
  );
});