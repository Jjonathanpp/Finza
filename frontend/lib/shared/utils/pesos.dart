// Punto de miles: 1250000 → 1.250.000.
String miles(int numero) => numero.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

// Como en la maqueta: pesos sin centavos y con punto de miles (200000 → $ 200.000, -5000 → −$ 5.000).
String pesos(double valor) => '${valor < 0 ? '−' : ''}\$ ${miles(valor.abs().round())}';
