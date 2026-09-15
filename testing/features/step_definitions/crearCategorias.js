const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

let contador = 0;

// Cuenta nueva por escenario: el test se puede repetir sin limpiar la base.
Given('que tengo una cuenta nueva para probar categorías', async function () {
  const unico = `${Date.now()}${contador++}`;
  const response = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `categorias.${unico}@test.com`,
      password: 'Password123!',
      usuario: { nombre: 'Test', apellido: 'Categorias', dni: Number(unico.slice(-9)) }
    })
  });
  assert.strictEqual(response.status, 201, `No se pudo registrar la cuenta de prueba (status ${response.status})`);
  this.cuentaId = (await response.json()).id;
});

async function crearCategoria(world, cuentaId, datos) {
  // Las celdas vacías no se mandan, así se prueban los campos faltantes.
  const body = Object.fromEntries(Object.entries(datos).filter(([, valor]) => valor !== ''));
  const response = await fetch(`${BACKEND_URL}/api/categorias?cuentaId=${cuentaId}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  world.status = response.status;
  world.body = await response.json().catch(() => ({}));
}

Given('que ya creé la categoría {string} de tipo {string}', async function (nombre, tipo) {
  await crearCategoria(this, this.cuentaId, { nombre, tipo });
  assert.strictEqual(this.status, 201, `No se pudo precrear la categoría "${nombre}" (status ${this.status})`);
});

When('creo una categoría con los siguientes datos:', async function (dataTable) {
  await crearCategoria(this, this.cuentaId, dataTable.rowsHash());
});

When('creo una categoría en la cuenta {int} con los siguientes datos:', async function (cuentaId, dataTable) {
  await crearCategoria(this, cuentaId, dataTable.rowsHash());
});

Then('la categoría se responde con código {int}', function (codigo) {
  assert.strictEqual(this.status, codigo, `Se esperaba ${codigo} pero llegó ${this.status}: ${JSON.stringify(this.body)}`);
});

Then('el mensaje de la respuesta es {string}', function (mensaje) {
  assert.strictEqual(this.body.message, mensaje);
});

Then('la categoría creada es {string} de tipo {string}', function (nombre, tipo) {
  const categoria = this.body.data;
  assert.ok(categoria && categoria.id, 'La respuesta no trae la categoría creada con su id');
  assert.strictEqual(categoria.nombre, nombre);
  assert.strictEqual(categoria.tipo, tipo);
  assert.strictEqual(categoria.esPredefinida, false);
});

Then('el campo {string} informa {string}', function (campo, mensaje) {
  assert.strictEqual(this.body.data && this.body.data[campo], mensaje);
});
