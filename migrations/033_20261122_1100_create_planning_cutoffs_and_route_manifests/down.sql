-- Reverts up.sql in reverse order. The history stored in the four tables is lost.
DROP TRIGGER IF EXISTS trg_route_manifest_stops_prevent_delete ON route_manifest_stops;
DROP TRIGGER IF EXISTS trg_route_manifest_stops_prevent_update ON route_manifest_stops;
DROP TRIGGER IF EXISTS trg_route_manifests_prevent_delete ON route_manifests;
DROP TRIGGER IF EXISTS trg_route_manifests_prevent_update ON route_manifests;
DROP TRIGGER IF EXISTS trg_planning_cutoff_dispatches_prevent_delete ON planning_cutoff_dispatches;
DROP TRIGGER IF EXISTS trg_planning_cutoff_dispatches_prevent_update ON planning_cutoff_dispatches;
DROP TRIGGER IF EXISTS trg_planning_cutoffs_prevent_delete ON planning_cutoffs;
DROP TRIGGER IF EXISTS trg_planning_cutoffs_prevent_update ON planning_cutoffs;

DROP FUNCTION IF EXISTS fn_route_manifest_stops_prevent_delete();
DROP FUNCTION IF EXISTS fn_route_manifest_stops_prevent_update();
DROP FUNCTION IF EXISTS fn_route_manifests_prevent_delete();
DROP FUNCTION IF EXISTS fn_route_manifests_prevent_update();
DROP FUNCTION IF EXISTS fn_planning_cutoff_dispatches_prevent_delete();
DROP FUNCTION IF EXISTS fn_planning_cutoff_dispatches_prevent_update();
DROP FUNCTION IF EXISTS fn_planning_cutoffs_prevent_delete();
DROP FUNCTION IF EXISTS fn_planning_cutoffs_prevent_update();

-- Children first; their indexes go with each table.
DROP TABLE IF EXISTS route_manifest_stops;
DROP TABLE IF EXISTS route_manifests;
DROP TABLE IF EXISTS planning_cutoff_dispatches;
DROP TABLE IF EXISTS planning_cutoffs;
