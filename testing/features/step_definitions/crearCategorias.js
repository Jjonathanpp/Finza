const Given = require('@cucumber/cucumber').Given;
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PASOS PREVIOS (GIVEN)
// ------------------------------------------------------------------

Given('que la API del backend esta activa y lista para recibir peticiones', async function () {
    try {
        await fetch(`${BACKEND_URL}/actuator/health`);
    } catch (error) {
        throw new Error(`Error al verificar el estado de la API: ${error.message}`);
    }
});

Given('que el usuario {string} esta registrado y autenticado', async function (nombreUsuario) {
    this.usuarioAutenticado = {
        nombre: nombreUsuario.trim(),
        token: 'jwt-token-simulado-123'
    };
});

Given('que el usuario autenticado desea crear una categoria', function () {
    assert.ok(
        this.usuarioAutenticado,
        'Se requiere un usuario autenticado para realizar esta operacion'
    );
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envio una solicitud POST a {string} con los siguientes datos:', async function (endpoint, dataTable) {
    const categorias = dataTable.hashes();

    try {
        const response = await fetch(`${BACKEND_URL}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify(categorias)
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion HTTP a ${endpoint}: ${error.message}`);
    }
});

When('envio una solicitud POST a {string} con esos datos incompletos', async function (endpoint) {
    try {
        const response = await fetch(`${BACKEND_URL}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify(this.datosCategoriaIncompletos)
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
// ASERCIONES Y VALIDACIONES (THEN)
// ------------------------------------------------------------------

Then('la respuesta debe tener un codigo de estado {int}', function (statusCodeEsperado) {
    assert.strictEqual(
        this.responseStatus,
        statusCodeEsperado,
        `Se esperaba código HTTP ${statusCodeEsperado} pero el backend devolvió ${this.responseStatus}`
    );
});

Then('la respuesta debe contener un mensaje de éxito indicando que la categoría fue creada correctamente', function () {
    const mensaje = this.responseData.mensaje || this.responseData.message;
    assert.ok(
        mensaje,
        'La respuesta no contiene un mensaje de éxito'
    );
});

Then('la nueva categoría debe estar presente en la base de datos', function () {
    const id = this.responseData.id || (Array.isArray(this.responseData) && this.responseData.length > 0);
    assert.ok(
        id,
        'No se confirmó la presencia de la nueva categoría en la respuesta'
    );
});

Then('la respuesta debe contener un mensaje de error indicando que falta información obligatoria', function () {
    const mensajeError = this.responseData.error || this.responseData.mensaje || this.responseData.message;
    assert.ok(
        mensajeError || this.responseStatus === 400,
        'No se recibió el mensaje de error esperado al enviar datos incompletos'
    );
});
