CREATE TABLE dispatch_ratings (
    dispatch_rating_id  SERIAL,
    dispatch_id          INT             NOT NULL UNIQUE,                 -- un despacho tiene a lo sumo una calificación
    score                 SMALLINT        NOT NULL,                        -- puntaje de 1 a 5
    comment                TEXT,                                            -- observaciones del cliente
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dispatch_rating_id),
    FOREIGN KEY (dispatch_id) REFERENCES dispatches(dispatch_id) ON DELETE CASCADE,
    CONSTRAINT chk_dispatch_ratings_score CHECK (score BETWEEN 1 AND 5)
);
