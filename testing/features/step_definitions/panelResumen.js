const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

// Función genérica para inyectar movimientos en la base de datos
async function registrarMovimiento(cuentaId, tipo, monto, fecha, estado) {
    const body = {
        perfilId: cuentaId, 
        movimientos: [{
            tipo: tipo,
            monto: monto,
            categoria: "TestBalance",
            fecha: fecha,
            estado: estado,
            descripcion: `Prueba de balance: ${estado} - ${fecha}`
        }]
    };

    const res = await fetch(`${BACKEND_URL}/api/movimientos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-Test-Cuenta-Id': cuentaId.toString()
        },
        body: JSON.stringify(body)
    });
    return res.json();
}

When('la {string} solicita su resumen financiero', async function (cuentaNombre) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const res = await fetch(`${BACKEND_URL}/api/panel/resumen?perfilId=${cuentaId}`, {
        method: 'GET',
        headers: { 'X-Test-Cuenta-Id': cuentaId.toString() }
    });
    
    this.status = res.status;
    this.body = await res.json();
    this.response = { status: this.status, data: this.body }; 
});

When('la {string} solicita su resumen financiero nuevamente', async function (cuentaNombre) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const res = await fetch(`${BACKEND_URL}/api/panel/resumen?perfilId=${cuentaId}`, {
        method: 'GET',
        headers: { 'X-Test-Cuenta-Id': cuentaId.toString() }
    });
    this.status = res.status;
    this.body = await res.json();
});

When('guardamos sus totales actuales en memoria', function () {
    const data = this.body.data;
    this.ingresosIniciales = parseFloat(data.totalIngresos) || 0;
    this.egresosIniciales = parseFloat(data.totalEgresos) || 0;
    this.saldoInicial = parseFloat(data.saldo) || 0;
});

Given('que la {string} registra un {string} de {string} para el balance', async function (cuentaNombre, tipo, monto) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    // Octubre 2026 para asegurar que cae en el mes actual del sistema
    await registrarMovimiento(cuentaId, tipo, monto, "15-10-2026", "APROBADO");
});

Given('que la {string} registra un {string} de {string} con fecha {string} y estado {string}', async function (cuentaNombre, tipo, monto, fecha, estado) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const fechaReal = fecha === "hoy" ? "15-10-2026" : fecha;
    await registrarMovimiento(cuentaId, tipo, monto, fechaReal, estado);
});

Then('sus ingresos deben haber aumentado en {string}', function (aumentoEsperado) {
    const ingresosActuales = parseFloat(this.body.data.totalIngresos) || 0;
    const diferencia = (ingresosActuales - this.ingresosIniciales).toFixed(2);
    assert.strictEqual(diferencia, parseFloat(aumentoEsperado).toFixed(2), `Los ingresos sumaron mal o filtraron mal.`);
});

Then('sus egresos deben haber aumentado en {string}', function (aumentoEsperado) {
    const egresosActuales = parseFloat(this.body.data.totalEgresos) || 0;
    const diferencia = (egresosActuales - this.egresosIniciales).toFixed(2);
    assert.strictEqual(diferencia, parseFloat(aumentoEsperado).toFixed(2), `Los egresos sumaron mal o filtraron mal.`);
});

Then('su saldo debe haber aumentado en {string}', function (aumentoEsperado) {
    const saldoActual = parseFloat(this.body.data.saldo) || 0;
    const diferencia = (saldoActual - this.saldoInicial).toFixed(2);
    assert.strictEqual(diferencia, parseFloat(aumentoEsperado).toFixed(2), `El saldo se calculó mal.`);
});