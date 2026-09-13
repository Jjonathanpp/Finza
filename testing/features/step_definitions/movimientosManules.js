const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PASOS PREVIOS (GIVEN)
// ------------------------------------------------------------------

Given('que la API del backend está activa y lista para recibir peticiones', async function () {
  const response = await fetch(`${BACKEND_URL}/api/health`);

  if (!response.ok) {
    throw new Error(`El backend no está disponible. Status: ${response.status}`);
  }
});


Given('que existe un usuario registrado con el email {string}', async function (email) {
  const response = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: email,
      password: 'Password123!',
      usuario: {
        nombre: 'Usuario',
        apellido: 'Existente',
        dni: 30999888
      }
    })
  });

  if (!response.ok) {
    throw new Error(`No se pudo precrear el usuario de prueba. Status: ${response.status}`);
  }
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envío una solicitud POST a {string} con los siguientes datos:', async function (endpoint, dataTable) {
  const rawData = dataTable.rowsHash();

  const payload = {
    email: rawData.email || '',
    password: rawData.password || '',
    usuario: {
      nombre: rawData.nombre || '',
      apellido: rawData.apellido || '',
      dni: rawData.dni ? Number(rawData.dni) : null
    }
  };

  try {
    const response = await fetch(`${BACKEND_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    this.responseStatus = response.status;

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

Then('la respuesta debe contener el mensaje de error de campo {string} {string}', function (campo, mensajeEsperado) {
  const mensajeObtenido = this.responseData.data ? this.responseData.data[campo] : undefined;

  assert.strictEqual(
    mensajeObtenido,
    mensajeEsperado,
    `Se esperaba el mensaje "${mensajeEsperado}" para el campo "${campo}", pero el backend devolvió "${mensajeObtenido}"`
  );
});


Then('la respuesta debe indicar los campos faltantes requeridos', function () {
  const tieneErrores = this.responseData && this.responseData.data && Object.keys(this.responseData.data).length > 0;

  assert.ok(
    tieneErrores,
    'La respuesta no proporcionó detalles de validación sobre los campos requeridos faltantes'
  );
});

Then('la respuesta debe contener el mensaje de error {string}', function (mensajeEsperado) {
  const mensajeObtenido = this.responseData.message;

  assert.strictEqual(
    mensajeObtenido,
    mensajeEsperado,
    `Se esperaba el mensaje "${mensajeEsperado}", pero el backend devolvió "${mensajeObtenido}"`
  );
});