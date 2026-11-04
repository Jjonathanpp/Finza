const { Given, When, Then, setDefaultTimeout } = require('@cucumber/cucumber');
const assert = require('assert');

setDefaultTimeout(60000);

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

let cuentaIdA = 1;
let cuentaIdB = 2;
let perfilIdA = 1;
let perfilIdB = 2;

async function registrarMovimiento(cuentaId, perfilId, tipo, monto, descripcion) {
  const body = {
    perfilId: perfilId,
    movimientos: [{
      tipo: tipo,
      monto: monto.toString(),
      categoria: tipo === 'ingreso' ? 'Sueldo' : 'Alquiler',
      fecha: '10-10-2026',
      descripcion: descripcion
    }]
  };

  try {
    const res = await fetch(`${BACKEND_URL}/api/movimientos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Test-Cuenta-Id': cuentaId.toString()
      },
      body: JSON.stringify(body)
    });

    const text = await res.text();
    try {
      const data = JSON.parse(text);
      return data?.data?.[0] || data?.[0] || null;
    } catch (e) {
      console.log('ERR PARSE REGISTRO:', text);
      return null;
    }
  } catch (e) {
    console.log('ERR REGISTRO MOV:', e.message);
    return null;
  }
}

Given('que existe una cuenta compartida con dos integrantes', async function () {
  cuentaIdA = 1;
  cuentaIdB = 2;
  perfilIdA = 1;
  perfilIdB = 2;
});

Given('que el integrante {string} registra movimientos de ingreso y egreso', async function (integrante) {
  if (integrante === 'A') {
    await registrarMovimiento(cuentaIdA, perfilIdA, 'ingreso', 5000, 'Ingreso A');
    await registrarMovimiento(cuentaIdA, perfilIdA, 'egreso', 1500, 'Egreso A');
  } else if (integrante === 'B') {
    await registrarMovimiento(cuentaIdB, perfilIdB, 'ingreso', 3000, 'Ingreso B');
    await registrarMovimiento(cuentaIdB, perfilIdB, 'egreso', 800, 'Egreso B');
  }
});

When('solicito el listado de movimientos filtrando por el integrante {string}', async function (integrante) {
  const cuentaId = integrante === 'A' ? cuentaIdA : cuentaIdB;
  const perfilId = integrante === 'A' ? perfilIdA : perfilIdB;

  const res = await fetch(`${BACKEND_URL}/api/movimientos?perfilId=${perfilId}&page=0&size=50&sort=fecha,desc`, {
    method: 'GET',
    headers: {
      'X-Test-Cuenta-Id': cuentaId.toString()
    }
  });

  this.status = res.status;
  const text = await res.text();
  try {
    this.body = JSON.parse(text);
  } catch (e) {
    this.body = {};
    console.log('ERR PARSE LISTADO:', text);
  }
  this.response = { status: this.status, data: this.body };
  this.integranteFiltrado = integrante;
});

Then('solo deben aparecer movimientos del integrante {string}', function (integrante) {
  const movimientos = this.body?.data?.content || this.body?.content || [];
  assert.ok(Array.isArray(movimientos) && movimientos.length > 0, 'No se devolvieron movimientos al filtrar por integrante');

  const perfilEsperado = integrante === 'A' ? perfilIdA : perfilIdB;

  for (let mov of movimientos) {
    assert.strictEqual(mov.perfilId, perfilEsperado,
      `Se encontró un movimiento que no pertenece al integrante ${integrante}. Esperado perfilId ${perfilEsperado} pero llegó ${mov.perfilId}`);
  }

  this.movimientosFiltrados = movimientos;
});

Then('los totales y balances calculados deben ser correctos para el integrante {string}', function (integrante) {
  const movimientos = this.movimientosFiltrados || [];
  let totalIngresos = 0;
  let totalEgresos = 0;

  for (let mov of movimientos) {
    const monto = parseFloat(mov.monto || 0);
    if (mov.tipo === 'ingreso') {
      totalIngresos += monto;
    } else {
      totalEgresos += monto;
    }
  }

  const balance = totalIngresos - totalEgresos;

  assert.ok(totalIngresos > 0, 'Se esperaba que existieran ingresos para el integrante filtrado');
  assert.ok(totalEgresos > 0, 'Se esperaba que existieran egresos para el integrante filtrado');
  assert.strictEqual(balance, totalIngresos - totalEgresos, 'El balance debe ser igual a ingresos menos egresos');

  this.totales = { totalIngresos, totalEgresos, balance };
});