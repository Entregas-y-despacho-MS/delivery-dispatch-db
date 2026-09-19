# delivery_evidences

Evidencia digital de una entrega o de un recojo de devolución: foto, firma o código OTP.

## Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| delivery_evidence_id | UUID | NO | — (generado por la app móvil) | Identificador de la evidencia |
| dispatch_id | INT | NO | — | Despacho al que corresponde |
| type | VARCHAR(20) | NO | — | `photo`, `signature` u `otp` |
| file_url | TEXT | YES | — | URL al archivo, si es foto o firma; ya comprimido por la app antes de enviarse |
| otp_code | VARCHAR(10) | YES | — | Código OTP, si el tipo es `otp` |
| created_at | TIMESTAMPTZ | NO | NOW() | Fecha de registro |
| updated_at | TIMESTAMPTZ | NO | NOW() | Última modificación |

## Relationships

| Column | Reference | Description |
|--------|-----------|--------------|
| dispatch_id | dispatches.dispatch_id | Despacho (entrega o recojo de devolución) al que respalda esta evidencia |

## Business rules

- El repartidor registra evidencia digital de la entrega (RF-U05) y también al retirar una devolución en domicilio, verificando el estado físico del producto (RF-U23).
- Una evidencia deja de tener sentido si se elimina su despacho (`ON DELETE CASCADE`).

## Technical notes

- **PK en UUID, no SERIAL.** Esta tabla la crea directamente la app móvil del repartidor, que puede quedarse sin conexión durante una entrega (RF-U13). El repartidor necesita generar el identificador de la evidencia en el dispositivo, offline, antes de sincronizar con el servidor — con un `SERIAL` eso es imposible, porque el ID solo existiría después de que el INSERT llegue al servidor. Por eso el UUID no lleva `DEFAULT`: lo genera la app, no la base de datos.
- **Usar UUID v7, no v4.** v7 embebe el timestamp de creación, así que los INSERTs quedan ordenados y no fragmentan el índice de la PK (a diferencia de v4, que es puramente aleatorio). Postgres no valida la versión del UUID, pero **el backend NestJS sí**: `ParseUUIDPipe` y `@IsUUID()` de `class-validator` solo aceptan v3/v4/v5 por default (verificado contra la documentación oficial de NestJS) — cualquier endpoint que reciba `delivery_evidence_id` como parámetro debe configurarse explícitamente con `version: '7'` (`new ParseUUIDPipe({ version: '7' })`, `@IsUUID('7')`), o va a rechazar un ID válido con error 400.

