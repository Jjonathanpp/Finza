// Temporal: solo lo usa Mercado Pago. Vincular se abre en el navegador, donde no viaja el token,
// así que todavía manda la cuenta 1. El resto de la app ya usa la cuenta del token.
// Cuando Mercado Pago use el token, se borra este archivo y el compilador marca cada lugar que hay que cambiar.
const int cuentaIdTemporal = 1;
