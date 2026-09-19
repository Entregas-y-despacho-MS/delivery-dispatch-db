INSERT INTO roles (name) VALUES
    ('root'),
    ('admin'),
    ('coordinator'),
    ('supervisor'),
    ('driver');
-- "client" no es un rol interno: el Cliente Final no tiene cuenta, accede por token de seguimiento.
-- "root" y "admin" no vienen del documento de requerimientos — son roles de sistema que cualquier
-- backend real necesita (cuenta semilla que nunca se borra, y gestión de usuarios/catálogos/settings),
-- aunque ningún RF los mencione explícitamente. Ver DICTIONARY.md para el detalle de cada uno.
