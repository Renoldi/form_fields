PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS assetsss;
DROP TABLE IF EXISTS asset_v2;
DROP TABLE IF EXISTS master_inspection_forms_v2;
DROP TABLE IF EXISTS master_inspections_v2;
DROP TABLE IF EXISTS pending_inspections_v2;

COMMIT;
