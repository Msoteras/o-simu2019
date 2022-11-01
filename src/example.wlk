class Linea{
	const nroDeTelefono
	var property packs = []
	var property consumos = []
	var tipoDeLinea
	
	method costoPromedio(fechaInicial, fechaFinal) = self.costoDeConsumosEntre(fechaInicial, fechaFinal)/ self.cantidadDeConsumosEntre(fechaInicial, fechaFinal)
	
	method costoDeConsumosEntre(fechaInicial, fechaFinal)= self.consumosEntre(fechaInicial, fechaFinal).sum{unConsumo=>unConsumo.costo()}
	
	method consumosEntre(fechaInicial, fechaFinal) = consumos.filter{unConsumo => unConsumo.fecha().between(fechaInicial, fechaFinal)}
	
	method cantidadDeConsumosEntre(fechaInicial, fechaFinal) = self.consumosEntre(fechaInicial, fechaFinal).size()
	
	method costoTotalEnElUltimoMes() =  self.costoDeConsumosEntre(fechaHoy, fechaHoy.minusDays(30))
	
	method agregarPack(unPack){packs.add(unPack)}
	
	method puedeHacer(unConsumo) = tipoDeLinea.puedeHacer(unConsumo, self)
	
	method realizar(unConsumo) {tipoDeLinea.realizar(unConsumo, self)}
	
		
	method limpiezaDePacks(){
		packs.removeAllSuchThat{unPack => unPack.estaAcabadoOVencido()}
	}
	
	method hayAlgunPackQueSatisface(unConsumo) = packs.any{pack => pack.puedeSatisfacer(unConsumo)}
	
	method agregarConsumo(unConsumo)= consumos.add(unConsumo)
}

const fechaHoy = new Date()


/******PACKS*******/
class Pack{
	const vencimiento

	
	method estaVencido() = vencimiento < fechaHoy && self.tieneVencimiento()
	
	method tieneVencimiento() = vencimiento != null
	
	method puedeSatisfacer(unConsumo) = self.satisface(unConsumo) && !self.estaVencido()
	
	method satisface(unConsumo)
	
	method hacer(unConsumo)
	
	method estaAcabadoOVencido() = self.estaVencido() || self.estaAcabado()
	
	method estaAcabado()
}

class Credito inherits Pack{
	var creditoDisponible

	override method satisface(unConsumo) = unConsumo.costo() <= creditoDisponible
	
	override method hacer(unConsumo){
		creditoDisponible -= unConsumo.costo()
	}
	
	override method estaAcabado() = creditoDisponible == 0
}

class MBLibres inherits Pack{
	var mbDisponibles

	override method satisface(unConsumo) = unConsumo.cantidadMB() <= mbDisponibles && !unConsumo.esDeLlamada()
	
	override method hacer(unConsumo){
		mbDisponibles -= unConsumo.cantidadMB()
	}
	
	override method estaAcabado() = mbDisponibles == 0
}

class LlamadasGratis inherits Pack{

	override method satisface(unConsumo) =  unConsumo.esDeLlamada()
	
	override method hacer(unConsumo){
		
	}
	override method estaAcabado() = false
}

class InternetIlimitado inherits Pack{
	
	override method satisface(unConsumo) = unConsumo.seHizoEnFinde() && !unConsumo.esDeLlamada()
	
	override method hacer(unConsumo){}
	
	override method estaAcabado() = false
}

class MBLibresPlusPlus inherits MBLibres{
	
	override method satisface(unConsumo) =
		super(unConsumo) || (unConsumo.cantidadMB() < 0.1 && !unConsumo.esDeLlamada())
	
	override method hacer(unConsumo){
		if(!(unConsumo.cantidadMB()<=0.1)){super(unConsumo)}
	}
}

/*******CONSUMOS********/

// var fecha= newDate(day=10,month=10,year=2022)
class Consumo{
	const property fecha
	
	method costo()
	
	method seHizoEnFinde() = fecha.dayOfWeek() == sunday or fecha.dayOfWeek() == saturday
}

class Llamada inherits Consumo{
	const segundos
	var precioVariable 
	var precioFijo
	const property esDeLlamada = true
	
	
	override method costo() = precioFijo + precioVariable * (segundos-30).max(0)
	
}

class Internet inherits Consumo{
	const property cantidadMB
	var precio
	const property esDeLlamada = false
	
	override method costo() = self.cantidadMB() * precio
	
}

/**********TIPOS DE LINEA**********/
object comun{
	
	method puedeHacer(unConsumo, linea) = linea.hayAlgunPackQueSatisface(unConsumo)
	
	method realizar(unConsumo, linea) {
		if(!linea.puedeHacer(unConsumo)){
			throw new DomainException(message = "El consumo no puede ser realizado")  
		}
		else{
			linea.agregarConsumo(unConsumo)
			linea.packs().reverse().find{unPack => unPack.puedeSatisfacer(unConsumo)}.hacer(unConsumo)
		}
	}
}

object platinum{
	
	method puedeHacer(unConsumo, linea) = true
	
	method realizar(unConsumo, linea) {
		linea.agregarConsumo(unConsumo)
		
		if(linea.hayAlgunPackQueSatisface(unConsumo)){
			linea.packs().reverse().find{unPack => unPack.puedeSatisfacer(unConsumo)}.hacer(unConsumo)
		}
	}
}
class Black{
	var deuda = 0	
	
	method puedeHacer(unConsumo, linea) = true
	
	method realizar(unConsumo, linea) = 
		if(!linea.hayAlgunPackQueSatisface(unConsumo)){
			deuda += unConsumo.costo()
		}
		else{
			linea.agregarConsumo(unConsumo)
			linea.packs().reverse().find{unPack => unPack.puedeSatisfacer(unConsumo)}.hacer(unConsumo)//tambien podria delegar esto
		}
}

