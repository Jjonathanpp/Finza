const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';
let contador = 0;

// ------------------------------------------------------------------
// ANTECEDENTES Y GIVEN
// ------------------------------------------------------------------

Given('que tengo una cuenta nueva autenticada para probar presupuestos', async function () {
    const unico = `${Date.now()}${contador++}`;
    const email = `presupuestos.${unico}@test.com`;
    const password = 'Password123!';

    // Registro
    const regRes = await fetch(`${BACKEND_URL}/api/auth/registro`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email,
            password,
            usuario: { nombre: 'Test', apellido: 'Presupuestos', dni: Number(unico.slice(-9)) }
        })
    });
    assert.strictEqual(regRes.status, 201, `Error en registro: ${regRes.status}`);
    const regJson = await regRes.json();
    this.cuentaId = regJson.id;

    // Login
    const loginRes = await fetch(`${BACKEND_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });
    assert.strictEqual(loginRes.status, 200, `Error en login: ${loginRes.status}`);
    const loginJson = await loginRes.json();
    this.token = loginJson.data.token;
    this.categoriasMap = {};
});

Given('que tengo creadas las categorías de egreso {string}, {string} y {string}', async function (cat1, cat2, cat3) {
    const nombres = [cat1, cat2, cat3];
    
    // Obtenemos las categorías existentes (globales o previas)
    const listRes = await fetch(`${BACKEND_URL}/api/categorias?cuentaId=${this.cuentaId}`, {
        headers: { 'Authorization': `Bearer ${this.token}` }
    });
    const listJson = await listRes.json().catch(() => ({ data: [] }));
    const categoriasExistentes = Array.isArray(listJson.data) ? listJson.data : [];

    for (const nombre of nombres) {
        const existente = categoriasExistentes.find(c => c.nombre.toLowerCase() === nombre.toLowerCase());
        
        if (existente) {
            this.categoriasMap[nombre] = existente.id;
        } else {
            const res = await fetch(`${BACKEND_URL}/api/categorias?cuentaId=${this.cuentaId}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.token}`
                },
                body: JSON.stringify({
                    nombre,
                    tipo: 'EGRESO',
                    color: '#3B82F6'
                })
            });
            const json = await res.json();
            assert.ok([200, 201].includes(res.status), `Fallo creando categoría ${nombre}: ${res.status}`);
            this.categoriasMap[nombre] = json.data.id;
        }
    }
});

Given('tengo configurados los siguientes presupuestos para el mes {int} del año {int}:', async function (mes, anio, dataTable) {
    const filas = dataTable.hashes();
    for (const fila of filas) {
        const categoriaId = this.categoriasMap[fila.categoria];
        assert.ok(categoriaId, `No se encontró la categoría mapeada: ${fila.categoria}`);

        const res = await fetch(`${BACKEND_URL}/api/presupuestos`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.token}`
            },
            body: JSON.stringify({
                categoriaId,
                montoTope: parseFloat(fila.montoTope),
                mes,
                anio
            })
        });
        assert.strictEqual(res.status, 201, `Fallo al crear presupuesto para ${fila.categoria}: ${res.status}`);
    }
});

Given('que registro los siguientes movimientos en el mes {int} del año {int}:', async function (mes, anio, dataTable) {
    const movimientos = dataTable.hashes().map(f => ({
        tipo: f.tipo,
        monto: f.monto,
        categoria: f.categoria,
        descripcion: f.descripcion,
        fecha: f.fecha
    }));

    const res = await fetch(`${BACKEND_URL}/api/movimientos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.token}`
        },
        body: JSON.stringify({ movimientos })
    });
    assert.strictEqual(res.status, 201, `Fallo registrando movimientos: ${res.status}`);
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('consulto los presupuestos del mes {int} del año {int}', async function (mes, anio) {
    // Agregamos el "/mes" a la ruta para que coincida con el Controller
    const res = await fetch(`${BACKEND_URL}/api/presupuestos/mes?mes=${mes}&anio=${anio}`, {
        method: 'GET',
        headers: { 'Authorization': `Bearer ${this.token}` }
    });
    this.responseStatus = res.status;
    this.responseData = await res.json().catch(() => ({}));
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

Then('para la categoría {string} el monto gastado debe ser {float}', function (nombreCategoria, montoEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === nombreCategoria);

    assert.ok(cat, `Categoría "${nombreCategoria}" no encontrada en la respuesta`);
    assert.strictEqual(
        parseFloat(cat.montoGastado),
        montoEsperado,
        `Monto gastado en ${nombreCategoria}: esperado ${montoEsperado}, obtenido ${cat.montoGastado}`
    );
});

Then('para la categoría {string} el porcentaje consumido debe ser {float}', function (nombreCategoria, porcentajeEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === nombreCategoria);

    assert.ok(cat, `Categoría "${nombreCategoria}" no encontrada en la respuesta`);
    assert.strictEqual(
        parseFloat(cat.porcentajeConsumo),
        porcentajeEsperado,
        `Porcentaje en ${nombreCategoria}: esperado ${porcentajeEsperado}%, obtenido ${cat.porcentajeConsumo}%`
    );
});