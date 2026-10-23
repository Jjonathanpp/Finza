const { Then } = require('@cucumber/cucumber');
const assert = require('assert');

Then('la respuesta del cálculo debe tener codigo de estado {int}', function (codigoEsperado) {
    assert.strictEqual(
        this.responseStatus,
        codigoEsperado,
        `Se esperaba status ${codigoEsperado} pero llegó ${this.responseStatus}`
    );
});

Then('para la categoría {string} el monto gastado del cálculo debe ser {float}', function (nombreCategoria, montoEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === nombreCategoria);

    assert.ok(cat, `Categoría "${nombreCategoria}" no encontrada en la respuesta`);
    assert.strictEqual(
        parseFloat(cat.montoGastado),
        montoEsperado,
        `Monto gastado en ${nombreCategoria}: esperado ${montoEsperado}, obtenido ${cat.montoGastado}`
    );
});

Then('para la categoría {string} el porcentaje consumido del cálculo debe ser {float}', function (nombreCategoria, porcentajeEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === nombreCategoria);

    assert.ok(cat, `Categoría "${nombreCategoria}" no encontrada en la respuesta`);
    assert.strictEqual(
        parseFloat(cat.porcentajeConsumo),
        porcentajeEsperado,
        `Porcentaje en ${nombreCategoria}: esperado ${porcentajeEsperado}%, obtenido ${cat.porcentajeConsumo}%`
    );
});

Then('para la categoría {string} el estado del cálculo debe ser {string}', function (nombreCategoria, estadoEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === nombreCategoria);

    assert.ok(cat, `Categoría "${nombreCategoria}" no encontrada en la respuesta`);
    assert.strictEqual(
        cat.estado,
        estadoEsperado,
        `Estado en ${nombreCategoria}: esperado ${estadoEsperado}, obtenido ${cat.estado}`
    );
});