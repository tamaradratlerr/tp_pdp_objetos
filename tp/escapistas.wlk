class Entrada{
  const property banda
  const fecha
  const precioBase = 1000

  method precioFinal() = precioBase + productora.impuesto()
  method anioAnterior() = fecha.year() == new Date().year() -1
  method nombreBanda() = banda.nombre()
}

//lo hice object por que es solo 1
object productora {
  //lo inicialiso como 0 (porque al ser un objeto me lo pide sino da error) pero con lo dep property la productora puede cambiarlo cuando quiera (por el setter)
  var property impuesto = 0 
  const asistentes = #{}
  const bandas = #{}

  //hago estas funciones para probarlo
    method agregarBanda(unaBanda) {
    bandas.add(unaBanda)
  }

  method agregarAsistente(unAsistente) {
    asistentes.add(unAsistente)
  }

  //acá uso declaratividad: uso mensajes de colecciones (sum, filter, map, count) en vez de recorrer a mano.
  //y también uso encapsulamiento 
  
  method importeTotal() = asistentes.sum({asistente => asistente.totalImporteRecolectado()})
  method presupuestoBandas() = bandas.sum({banda => banda.presupuesto()})
  
  method gananciaTotal() = self.importeTotal() - self.presupuestoBandas()
  method totalEntradas() = asistentes.sum({asistente => asistente.cantidadEntradas()})
  method entradasVendidasDe(banda) = asistentes.sum({asistente => asistente.cantidadEntradasDe(banda)})
  method bandaPopular() = bandas.max({banda => self.entradasVendidasDe(banda)})
  method bonificarVip() {
    asistentes.forEach({asistente => asistente.bonificar()})
  }
}


class SinSaldoException inherits Exception{}

class Asistente{
  // acá hago composición porque tiene un atributo abono, que es otro objeto que colabora con él para resolver cosas.
  // el asistente delega en el abono el cálculo del precio a pagar y la bonificación, sin conocer cómo se implementan esas operaciones.
  // y así puedo tener distintos tipos de abono, como Vip y fan, que responden de forma diferente a los mismos mensajes.
  // también usa el polimorfismo y evita tener que agregar condicionales en Asistente.
  const abono
  //historial es una lista porque pueden repetirse las entradas
  const historial = []
  var property dinero

  method hayDinero() = dinero > 0

  method montoPagar(entrada) = abono.pagar(entrada.precioFinal())

  method comprarEntradas(entrada) {
    if (!self.hayDinero()) {
      //uso manejon de errores lo que vimos en la última clase, porque necesito contemplar la situación en la que un asistente intenta comprar una entrada sin tener saldo disponible.
      // para eso verifico la condición con hayDinero() y, si no tiene dinero, lanzo una excepción que permite señalar que la compra no se puede realizar y 
      // evito que se continúe con el descuento del dinero y el registro de la entrada
      throw new SinSaldoException(message = "No hay saldo disponible")
    }
    dinero -= self.montoPagar(entrada)
    historial.add(entrada)
  }


  // acá por ejemplo use encapsulamiento porque cada objeto se ocupa de sus propios datos y responsabilidades.
  // por ejemplo, cuando necesito saber qué entradas son del año anterior, el asistente le pregunta a cada entrada mediante anioAnterior(),
  // en lugar de acceder directamente a su fecha y hacer el cálculo. 
  // así cada clase conoce y administra sus propias cosas
  
  method entradasAnioAnterior() = historial.filter({entrada => entrada.anioAnterior()})
  method nombreBandas() = historial.map({entrada => entrada.nombreBanda()})
  method nombreBandasSinRepetir() = self.nombreBandas().asSet()
  //no especifica si no quiere que se repitan los nombres pero por las dudas lo hice


  //las funciones para poder respodbner a la productora
  method bonificar() {
    abono.bonificar()
  }
  method totalImporteRecolectado() = historial.sum({entrada => entrada.precioFinal()})
  method cantidadEntradas() = historial.size()
  method cantidadEntradasDe(bandaBuscada) = historial.count({entrada => entrada.banda() == bandaBuscada})

} 

//lo hago class ya que pueden haber muchos vip con distintos porcentajes y fan lo hago object porque solo hay un tipo de fan
class Vip{
  var porcentajeDescuento

  method bonificar(){
    porcentajeDescuento += 1
  }

  method pagar(precio) = precio * (100 - porcentajeDescuento) / 100
}

object fan {
  method pagar(precio) = precio
  method bonificar(){
    //fan no hace nada si se hace abono.bonificar()
  }
}


// uso HERENCIA entre las bandas porque las tres comparten comportamiento: todas tienen nombre,
// canon y calculan su presupuesto igual. sólo se diferencian en la popularidad y el gasto extra.
// elijo herencia y no composición porque el género de una banda es una característica estática:
// una banda de rock no se vuelve trapera durante la ejecución. la composición la uso para el abono,
// que sí podría cambiar, y porque no se puede cambiar la clase de un objeto en tiempo de ejecución.

class Banda {
  //pongo el property porque entrada necesita saber su nombre para mandarselo a la asistente y pongo const (que me deja solo el getter) ya que no cambia el nombre
  const property nombre
  const canonBase = 1000000

  // escribo presupuesto() una sola vez acá y uso self.canon() en vez de leer un atributo.
  // al mandarme el mensaje a mí misma uso lo del method lookup, que busca primero en la clase
  // de la instancia: por eso Trap puede redefinir canon() con override y este mismo presupuesto()
  // le sirve igual, sin tocar una línea.

  method presupuesto() = self.canon() + self.extra()

  method canon() = canonBase
  method largoNombre() = self.nombre().length()
  
  // Banda es una clase abstracta
  // declaro popularidad() y extra() sólo con la firma, sin cuerpo, porque no hay un cálculo
  // común a todas. son metodos abstractos, y al tenerlos Wollok ya no me deja instanciar Banda.
  // cada subclase está obligada a redefinirlos.

  method popularidad()
  method extra()
}

class Rock inherits Banda {
  const solos

  override method extra() = 10000
  override method popularidad() = solos * 100
}

class Trap inherits Banda {
  const hielo

  method hayHielo() = hielo > 0

  override method extra() = 0

  override method popularidad() {
    if (self.hayHielo()) {
      return 1000
    } else {
      return 0
    }
  }

  override method canon() = canonBase * self.popularidad()
}

class Indie inherits Banda {
  const instrumentos

  override method popularidad() = 3.14 * self.largoNombre()

  override method extra() = instrumentos.size() * 500
}
