const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
let contador = 0;

// ------------------------------------------------------------------
// ANTECEDENTES (GIVEN)
// ------------------------------------------------------------------

Given('que tengo una cuenta nueva autenticada para probar los reportes', async function () {
    const unico = `${Date.now()}${contador++}`;
    const email = `reportes.${unico}@test.com`;
    const password = 'Password123!';

    // 1. Registrar
    await fetch(`${BACKEND_URL}/api/auth/registro`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email, password,
            usuario: { nombre: 'Test', apellido: 'Reportes', dni: Number(unico.slice(-9)) }
        })
    });

    // 2. Login para obtener el token
    const resLogin = await fetch(`${BACKEND_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });
    
    const json = await resLogin.json();
    this.token = json.data.token;
});

Given('existen los siguientes movimientos registrados en la cuenta:', async function (dataTable) {
    const movimientos = dataTable.hashes().map(fila => ({
        tipo: fila.tipo,
        monto: fila.monto,
        categoria: fila.categoria,
        descripcion: fila.descripcion,
        fecha: fila.fecha // Formato dd-MM-yyyy esperado por el request
    }));

    const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.token}`
        },
        body: JSON.stringify({ movimientos: movimientos }) // MovimientosRegistroRequest
    });

    assert.strictEqual(response.status, 201, `Fallo al pre-cargar los movimientos: ${response.status}`);
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('solicito el resumen del panel con startDate {string} y endDate {string}', async function (startDate, endDate) {
    const response = await fetch(`${BACKEND_URL}/api/panel/resumen?startDate=${startDate}&endDate=${endDate}`, {
        method: 'GET',
        headers: { 'Authorization': `Bearer ${this.token}` }
    });
    
    this.responseStatus = response.status;
    this.responseData = await response.json().catch(() => ({}));
});

When('solicito los gastos por categoría con startDate {string} y endDate {string}', async function (startDate, endDate) {
    const response = await fetch(`${BACKEND_URL}/api/panel/gastos-por-categoria?startDate=${startDate}&endDate=${endDate}`, {
        method: 'GET',
        headers: { 'Authorization': `Bearer ${this.token}` }
    });
    
    this.responseStatus = response.status;
    this.responseData = await response.json().catch(() => ({}));
});

// ------------------------------------------------------------------
// ASERCIONES (THEN)
// ------------------------------------------------------------------

Then('la respuesta debe tener un codigo de estado {int}', function (codigoEsperado) {
    assert.strictEqual(
        this.responseStatus, 
        codigoEsperado, 
        `Se esperaba status ${codigoEsperado} pero llegó ${this.responseStatus}`
    );
});

Then('el total de ingresos del período debe ser {int}', function (montoEsperado) {
    assert.strictEqual(this.responseData.data.totalIngresos, montoEsperado);
});

Then('el total de egresos del período debe ser {int}', function (montoEsperado) {
    assert.strictEqual(this.responseData.data.totalEgresos, montoEsperado);
});

Then('el saldo del período debe ser {int}', function (montoEsperado) {
    assert.strictEqual(this.responseData.data.saldo, montoEsperado);
});

Then('la respuesta debe contener el error {string}', function (mensajeEsperado) {
    // Buscar en el campo "message" o donde el backend mande la excepcion
    const mensajeObtenido = this.responseData.message || this.responseData.error;
    assert.ok(
        mensajeObtenido.includes(mensajeEsperado), 
        `Se esperaba el error "${mensajeEsperado}", se obtuvo: "${mensajeObtenido}"`
    );
});

Then('la categoría {string} debe tener un gasto total de {int}', function (nombreCategoria, montoEsperado) {
    const categorias = this.responseData.data.categorias;
    const categoriaEncontrada = categorias.find(c => c.nombre === nombreCategoria);
    
    assert.ok(categoriaEncontrada, `No se encontró la categoría ${nombreCategoria} en la respuesta`);
    assert.strictEqual(categoriaEncontrada.total, montoEsperado);
});