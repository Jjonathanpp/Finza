const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
let idMovimientoActual = null;

Given('que tengo un perfil nuevo para probar pendientes', async function () {
  // Reutilizamos la creación de cuenta para tener un entorno limpio
  const unico = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const response = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `pendientes.${unico}@test.com`,
      password: 'Password123!',
      usuario: { nombre: 'Test', apellido: 'Pendiente', dni: Number(unico.slice(-9)) }
    })
  });
  const data = await response.json();
  this.perfilId = data.id || 1; // Usamos el ID real o 1 por defecto
  this.cuentaId = data.cuentaId || 1; 
});

When('registro un movimiento de tipo {string} por {string} con estado {string}', async function (tipo, monto, estado) {
  const bodyMovimiento = {
    perfilId: this.perfilId,
    movimientos: [{
      tipo: tipo,
      monto: monto,
      categoria: "Gastos Varios",
      descripcion: "Test estado",
      fecha: "19-09-2026",
      estado: estado
    }]
  };

  const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(bodyMovimiento)
  });
  
  this.status = response.status;
  const body = await response.json().catch(() => ({}));
  if (body.data && body.data.length > 0) {
    idMovimientoActual = body.data[0].id;
  }
});

Then('la respuesta HTTP es {int}', function (codigoEsperado) {
  assert.strictEqual(this.status, codigoEsperado);
});

Then('al consultar los movimientos con estado {string}, el listado trae {string} resultados', async function (estado, cantidadEsperada) {
  // Le agregamos el perfilId a la URL para que no consulte el hardcodeado 1
  const response = await fetch(`${BACKEND_URL}/api/movimientos?estado=${estado}&perfilId=${this.perfilId}`);
  const body = await response.json();
  
  const content = body.content || [];
  assert.strictEqual(content.length.toString(), cantidadEsperada, `Se esperaban ${cantidadEsperada} movimientos en estado ${estado}, pero vinieron ${content.length}`);
});

Given('que tengo un movimiento pendiente registrado', async function () {
  const bodyMovimiento = {
    perfilId: this.perfilId,
    movimientos: [{
      tipo: "egreso",
      monto: "5000",
      categoria: "Test Eliminar",
      fecha: "19-09-2026",
      estado: "PENDIENTE"
    }]
  };

  const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(bodyMovimiento)
  });
  const body = await response.json();
  idMovimientoActual = body.data[0].id;
});

When('elimino ese movimiento', async function () {
  const response = await fetch(`${BACKEND_URL}/api/movimientos/${idMovimientoActual}`, {
    method: 'DELETE'
  });
  this.status = response.status;
});

When('confirmo el movimiento pasándolo a estado {string}', async function (nuevoEstado) {
  // ATENCIÓN: Este endpoint NO existe todavía en MovimientoController.java. 
  // Va a tirar 404 o 405 hasta que lo programemos.
  const response = await fetch(`${BACKEND_URL}/api/movimientos/${idMovimientoActual}/estado?nuevoEstado=${nuevoEstado}`, {
    method: 'PUT'
  });
  this.status = response.status;
});