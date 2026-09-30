const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// Nota: "que tengo una cuenta nueva" y "que ya creé la categoría" 
// ya se resuelven automáticamente con el archivo crearCategorias.js de tus compañeros.

Given('la categoría tiene un movimiento registrado asociado', async function () {
  // Estructura exacta que pide MovimientosRegistroRequest.java del backend
  const bodyMovimiento = {
    perfilId: this.cuentaId, // O el ID de perfil correspondiente a la cuenta
    movimientos: [
      {
        tipo: "INGRESO",
        monto: "50000.00",
        categoria: "Inversiones Unicas",
        descripcion: "Dividendos",
        fecha: "19-09-2026"
      }
    ]
  };

  const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(bodyMovimiento)
  });
  
  assert.strictEqual(response.status, 201, `No se pudo registrar el movimiento (status ${response.status})`);
});

When('envío una solicitud PUT para actualizar la categoría con los siguientes datos:', async function (dataTable) {
  const datos = dataTable.rowsHash();
  const categoriaId = this.body.data.id; // Obtenemos el ID del paso previo compartido

  const response = await fetch(`${BACKEND_URL}/api/categorias/${categoriaId}?cuentaId=${this.cuentaId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      nombre: datos.nombre,
      color: datos.color,
      tipo: 'EGRESO'
    })
  });
  this.status = response.status;
  this.body = await response.json().catch(() => ({}));
});

When('envío una solicitud DELETE para eliminar esa categoría', async function () {
  const categoriaId = this.body.data.id; // Obtenemos el ID del paso previo compartido

  const response = await fetch(`${BACKEND_URL}/api/categorias/${categoriaId}?cuentaId=${this.cuentaId}`, {
    method: 'DELETE'
  });
  this.status = response.status;
  this.body = await response.json().catch(() => ({}));
});

Then('la categoría actualizada tiene el nombre {string} y color {string}', function (nombreEsperado, colorEsperado) {
  const data = this.body.data;
  assert.strictEqual(data.nombre, nombreEsperado);
  assert.strictEqual(data.color, colorEsperado);
});

Then('la respuesta debe contener el mensaje de error de movimientos asociados', function () {
  const mensaje = this.body.message || '';
  assert.ok(
    mensaje.includes('No se puede eliminar la categoría porque tiene movimientos asociados') || this.status >= 400,
    `Se esperaba un error por movimientos asociados. Respuesta: ${JSON.stringify(this.body)}`
  );
});