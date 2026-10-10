const { Given, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

// Helper para crear múltiples movimientos de un saque
async function registrarLoteMovimientos(cuentaId, cantidad, tipo) {
    const movimientos = [];
    for (let i = 0; i < cantidad; i++) {
        movimientos.push({
            tipo: tipo,
            monto: "100.00",
            categoria: "TestListas",
            fecha: "15-10-2026",
            estado: "APROBADO",
            descripcion: `Lote autogenerado ${tipo} #${i}`
        });
    }

    const body = {
        perfilId: cuentaId, 
        movimientos: movimientos
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

Given('que la {string} genera {string} registros de {string} en lote', async function (cuentaNombre, cantidadStr, tipo) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const cantidad = parseInt(cantidadStr, 10);
    await registrarLoteMovimientos(cuentaId, cantidad, tipo);
});

Then('la lista de {string} debe tener como máximo {string} elementos', function (nombreLista, maximoStr) {
    const maximo = parseInt(maximoStr, 10);
    // Extraemos la lista directamente del body que guardó el otro archivo de test
    const lista = this.body.data[nombreLista]; 
    
    assert.ok(Array.isArray(lista), `El campo ${nombreLista} no es un array o no existe en el DTO`);
    assert.ok(lista.length <= maximo, `La lista ${nombreLista} trajo ${lista.length} elementos, violando el límite de ${maximo}`);
});

Then('todos los elementos de {string} deben tener esIngreso en {string}', function (nombreLista, valorBooleanoStr) {
    const valorEsperado = valorBooleanoStr === "true";
    const lista = this.body.data[nombreLista];

    // Imprimimos el primer elemento en consola para ver la estructura real del JSON
    if (lista.length > 0) {
        console.log(`\nEstructura real del DTO en la lista ${nombreLista}:`, lista[0]);
    }

    lista.forEach((movimiento, index) => {
        // Buscamos la propiedad bajo los nombres más comunes que genera Spring Boot
        let valorReal = movimiento.esIngreso;
        
        if (valorReal === undefined) {
            valorReal = movimiento.ingreso; // Alternativa de Jackson
        }
        
        // Si el DTO usa un String en lugar de boolean, lo adaptamos al vuelo
        if (valorReal === undefined && movimiento.tipo !== undefined) {
            valorReal = movimiento.tipo.toUpperCase() === "INGRESO";
        }

        assert.strictEqual(
            valorReal, 
            valorEsperado, 
            `El elemento en el índice ${index} de la lista ${nombreLista} no coincide con el tipo esperado. Objeto recibido: ${JSON.stringify(movimiento)}`
        );
    });
});