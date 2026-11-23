local Techniques = {
	version = "0.1.0",
	disclaimer = "Biblioteca descriptiva; no representa aprendizaje automático ni recomienda rutas verificadas.",
	items = {
		{
			id = "momentum-preservation",
			name = "Conservación de impulso",
			status = "unconfirmed",
			evidence = "Principio de análisis; aún no validado con telemetría de una experiencia autorizada.",
			metrics = { "velocidad observada", "cambio de velocidad" },
		},
		{
			id = "short-run-up",
			name = "Aproximación al salto",
			status = "unconfirmed",
			evidence = "Hipótesis; la predicción de saltos está prevista para v0.2.0.",
			metrics = { "distancia al borde", "velocidad observada" },
		},
	},
}

function Techniques.GetById(id)
	for _, technique in ipairs(Techniques.items) do
		if technique.id == id then
			return technique
		end
	end
	return nil
end

return Techniques
