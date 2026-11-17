# seed_plan_min_orders_per_route

ST-50.2 (ES-50, RF-A03) — siembra el parámetro `plan_min_orders_per_route`, que el generador de
lotes provisionales (`LotPlanner`) usa solo como advertencia (D-13).

- Inserta la clave con el valor propuesto `3`; es una propuesta inicial, no una política confirmada
  (confirmar con Operaciones).
- `ON CONFLICT (setting_key) DO NOTHING` conserva el valor si la clave ya estaba configurada.
- No cambia la forma de ninguna tabla ni toca filas existentes.
- Autorizada por Jaime; el backend la lee con un valor por defecto, de modo que su ausencia nunca
  bloquea al generador.

`down.sql` elimina únicamente esta clave.
