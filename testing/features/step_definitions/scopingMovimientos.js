const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

// Helper para crear movimientos inyectando la identidad
async function registrarMovimiento(cuentaId, tipo) {
    const body = {
        perfilId: cuentaId, 
        movimientos: [{
            tipo: tipo,
            monto: "1500.50",
            categoria: "PruebaScoping",
            fecha: "10-10-2026",
            descripcion: `Movimiento de ${tipo} creado por cuenta ${cuentaId}`
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
    
    const data = await res.json();
    return data.data[0].id;
}

Given('que la {string} crea un movimiento de {string}', async function (cuentaNombre, tipo) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const movId = await registrarMovimiento(cuentaId, tipo);

    if (cuentaId === 1) this.movIdCuenta1 = movId;
    else this.movIdCuenta2 = movId;
});

When('la {string} solicita su listado de movimientos', async function (cuentaNombre) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const res = await fetch(`${BACKEND_URL}/api/movimientos?perfilId=${cuentaId}`, {
        method: 'GET',
        headers: { 'X-Test-Cuenta-Id': cuentaId.toString() }
    });
    
    this.status = res.status;
    this.body = await res.json();
    // Compatibilidad con los asserts de listarMovimientos.js
    this.response = { status: this.status, data: this.body }; 
});

Then('solo debe ver sus movimientos de tipo {string}', function (tipoEsperado) {
    const movimientos = this.body.data.content;
    assert.ok(movimientos.length > 0, "El listado vino vacío, no se crearon los movimientos de prueba");
    
    const idsEncontrados = movimientos.map(m => m.id);

    // 1. Verificamos que el movimiento de la Cuenta 2 NO se haya filtrado hacia la Cuenta 1
    assert.ok(
        !idsEncontrados.includes(this.movIdCuenta2), 
        `Falla crítica: La Cuenta 1 pudo ver el movimiento ajeno (ID: ${this.movIdCuenta2})`
    );

    // 2. Verificamos que la Cuenta 1 SÍ pueda ver el suyo
    assert.ok(
        idsEncontrados.includes(this.movIdCuenta1), 
        `La Cuenta 1 no pudo encontrar su propio movimiento (ID: ${this.movIdCuenta1})`
    );
});

When('la {string} intenta eliminar ese movimiento ajeno', async function (cuentaNombre) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const movIdAjeno = this.movIdCuenta2; 

    const res = await fetch(`${BACKEND_URL}/api/movimientos/${movIdAjeno}`, {
        method: 'DELETE',
        headers: { 'X-Test-Cuenta-Id': cuentaId.toString() }
    });
    
    this.status = res.status;
    this.body = await res.json();
    this.response = { status: this.status, data: this.body };
});

When('la {string} intenta modificar ese movimiento ajeno con monto {string}', async function (cuentaNombre, nuevoMonto) {
    const cuentaId = cuentaNombre === "Cuenta 1" ? 1 : 2;
    const movIdAjeno = this.movIdCuenta2; 

    const bodyModificacion = {
        tipo: "egreso",
        monto: nuevoMonto,
        categoria: "Ataque",
        fecha: "12-12-2026",
        descripcion: "Intento de hackeo"
    };

    const res = await fetch(`${BACKEND_URL}/api/movimientos/${movIdAjeno}`, {
        method: 'PUT',
        headers: { 
            'Content-Type': 'application/json',
            'X-Test-Cuenta-Id': cuentaId.toString() 
        },
        body: JSON.stringify(bodyModificacion)
    });
    
    this.status = res.status;
    this.body = await res.json();
    this.response = { status: this.status, data: this.body };
});
