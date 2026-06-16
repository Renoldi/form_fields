-- migration: create core tables for the local DB
-- Run this SQL against the app database when performing manual migrations.

PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

-- V1: initial core tables
CREATE TABLE IF NOT EXISTS pending_inspections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- V2: ensure master_inspections index table exists
CREATE TABLE IF NOT EXISTS master_inspections (
  hseFormId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  formType TEXT DEFAULT ''
);

-- V2: auxiliary full-form table
CREATE TABLE IF NOT EXISTS master_inspection_forms (
  hseFormId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

-- V2: asset table
CREATE TABLE IF NOT EXISTS asset (
  assetId TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

COMMIT;

-- Sample inserts have been moved to migrations/sample_inserts.sql
-- Run that file separately when you want example/demo rows inserted.

-- Sample inserts: inline payloads for example/demo
-- Inserts for table "asset" (5 rows)
INSERT INTO "asset" ("payload","updated_at") VALUES ('{
  "assetId": "97502c88-9703-4712-a957-1d0985b3db65",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "assetNumber": "1",
  "assetName": "laptop",
  "assetType": "barang",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "createdDate": "2025-02-11T15:20:54.530",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-02-11T15:20:54.530",
  "id": "97502c88-9703-4712-a957-1d0985b3db65",
  "text": "laptop"
}', 1781586828000);
INSERT INTO "asset" ("payload","updated_at") VALUES ('{
  "assetId": "97502c88-9703-4712-a957-1d0985b3db65",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "assetNumber": "1",
  "assetName": "laptop",
  "assetType": "barang",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "createdDate": "2025-02-11T15:20:54.530",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-02-11T15:20:54.530",
  "id": "97502c88-9703-4712-a957-1d0985b3db65",
  "text": "laptop"
}', 1781586828001);
INSERT INTO "asset" ("payload","updated_at") VALUES ('{
  "assetId": "97502c88-9703-4712-a957-1d0985b3db65",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "assetNumber": "1",
  "assetName": "laptop",
  "assetType": "barang",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "createdDate": "2025-02-11T15:20:54.530",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-02-11T15:20:54.530",
  "id": "97502c88-9703-4712-a957-1d0985b3db65",
  "text": "laptop"
}', 1781586828002);
INSERT INTO "asset" ("payload","updated_at") VALUES ('{
  "assetId": "97502c88-9703-4712-a957-1d0985b3db65",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "assetNumber": "1",
  "assetName": "laptop",
  "assetType": "barang",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "createdDate": "2025-02-11T15:20:54.530",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-02-11T15:20:54.530",
  "id": "97502c88-9703-4712-a957-1d0985b3db65",
  "text": "laptop"
}', 1781586828003);
INSERT INTO "asset" ("payload","updated_at") VALUES ('{
  "assetId": "97502c88-9703-4712-a957-1d0985b3db65",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "assetNumber": "1",
  "assetName": "laptop",
  "assetType": "barang",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "createdDate": "2025-02-11T15:20:54.530",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-02-11T15:20:54.530",
  "id": "97502c88-9703-4712-a957-1d0985b3db65",
  "text": "laptop"
}', 1781586828004);

-- Inserts for table "form" (5 rows)
INSERT INTO "form" ("payload","updated_at") VALUES ('{
  "hseFormId": "cfab09ed-2fa0-4504-8b48-1446a6a9cfd1",
  "payload": "{\n  \"hseFormId\": \"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1\",\n  \"assetId\": \"\",\n  \"hseFormName\": \"Pemeriksaan kendaraan\",\n  \"hseFormCode\": \"\",\n  \"description\": \"\",\n  \"subscriptionId\": \"cc9d1bf4-d98b-4726-870a-9996eb4337ef\",\n  \"notes\": \"\",\n  \"isDeleted\": false,\n  \"createdBy\": \"9e7155fb-2fa7-42b3-888f-786224f5e561\",\n  \"hseFormType\": \"ASSET\",\n  \"createdDate\": \"2025-04-28T14:15:48.043\",\n  \"lastModifiedBy\": \"9e7155fb-2fa7-42b3-888f-786224f5e561\",\n  \"lastModifiedDate\": \"2025-04-28T14:15:48.043\",\n  \"items\": []\n}",
  1781586828280);
INSERT INTO "form" ("payload","updated_at") VALUES ('{ "hseFormId": "cfab09ed-2fa0-4504-8b48-1446a6a9cfd1", "payload": "{\\n  \\\"hseFormId\\\": \\\"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1\\\",\\n  \\\"assetId\\\": \\\"\\\",\\n  \\\"hseFormName\\\": \\\"Pemeriksaan kendaraan\\\" }", 1781586828281);
INSERT INTO "form" ("payload","updated_at") VALUES ('{ "hseFormId": "cfab09ed-2fa0-4504-8b48-1446a6a9cfd1", "payload": "{}" }', 1781586828282);
INSERT INTO "form" ("payload","updated_at") VALUES ('{ "hseFormId": "cfab09ed-2fa0-4504-8b48-1446a6a9cfd1", "payload": "{}" }', 1781586828283);
INSERT INTO "form" ("payload","updated_at") VALUES ('{ "hseFormId": "cfab09ed-2fa0-4504-8b48-1446a6a9cfd1", "payload": "{}" }', 1781586828284);

-- Inserts for table "master" (5 rows)
INSERT INTO "master" ("payload","updated_at") VALUES ('{
  "hseFormId": "227460fb-8566-49c9-a128-ad431480602d",
  "assetId": "",
  "hseFormName": "Membersihkan telinga",
  "hseFormCode": "",
  "description": "",
  "subscriptionId": "",
  "notes": "",
  "isDeleted": false,
  "createdBy": "",
  "hseFormType": "PROCESS",
  "createdDate": null,
  "lastModifiedBy": "",
  "lastModifiedDate": null,
  "items": [],
  "sections": [],
  "hseFormDataId": 0,
  "status": "",
  "failedItems": [],
  "needApprovalItems": [],
  "hseFormDataNumber": "",
  "assetNumber": "",
  "assetName": "",
  "assetType": "",
  "value": "",
  "inspectionFrequency": 0,
  "inspectionFrequencyUnit": "",
  "intendedInspectionDate": null,
  "intendedDate": null,
  "inspectedDate": null,
  "inspectionStatus": "",
  "nextInspectionDate": null,
  "showInCalendar": false
}', 1781586828300);
INSERT INTO "master" ("payload","updated_at") VALUES ('{ "hseFormId": "227460fb-8566-49c9-a128-ad431480602d", "assetId": "", "hseFormName": "Membersihkan telinga", "hseFormType": "PROCESS" }', 1781586828301);
INSERT INTO "master" ("payload","updated_at") VALUES ('{ "hseFormId": "227460fb-8566-49c9-a128-ad431480602d", "assetId": "", "hseFormName": "Membersihkan telinga", "hseFormType": "PROCESS" }', 1781586828302);
INSERT INTO "master" ("payload","updated_at") VALUES ('{ "hseFormId": "227460fb-8566-49c9-a128-ad431480602d", "assetId": "", "hseFormName": "Membersihkan telinga", "hseFormType": "PROCESS" }', 1781586828303);
INSERT INTO "master" ("payload","updated_at") VALUES ('{ "hseFormId": "227460fb-8566-49c9-a128-ad431480602d", "assetId": "", "hseFormName": "Membersihkan telinga", "hseFormType": "PROCESS" }', 1781586828304);

-- Inserts for table "pending_inspections" (5 rows)
INSERT INTO "pending_inspections" ("payload","status","created_at") VALUES ('{
  "hseFormId": "52e7ffdb-8812-40ea-9331-5360c165e6aa",
  "assetId": "",
  "hseFormName": "Audit SMK3 (1)",
  "hseFormCode": "",
  "description": "Audit Checklist SMK3",
  "subscriptionId": "cc9d1bf4-d98b-4726-870a-9996eb4337ef",
  "notes": "",
  "isDeleted": false,
  "createdBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "hseFormType": "PROCESS",
  "createdDate": "2025-08-06T11:30:22.120",
  "lastModifiedBy": "9e7155fb-2fa7-42b3-888f-786224f5e561",
  "lastModifiedDate": "2025-08-06T11:30:22.120",
  "items": []
}', 'NEW', 1781586828400);
INSERT INTO "pending_inspections" ("payload","status","created_at") VALUES ('{ "hseFormId": "52e7ffdb-8812-40ea-9331-5360c165e6aa", "hseFormName": "Audit SMK3 (1)" }', 'NEW', 1781586828401);
INSERT INTO "pending_inspections" ("payload","status","created_at") VALUES ('{ "hseFormId": "52e7ffdb-8812-40ea-9331-5360c165e6aa", "hseFormName": "Audit SMK3 (1)" }', 'NEW', 1781586828402);
INSERT INTO "pending_inspections" ("payload","status","created_at") VALUES ('{ "hseFormId": "52e7ffdb-8812-40ea-9331-5360c165e6aa", "hseFormName": "Audit SMK3 (1)" }', 'NEW', 1781586828403);
INSERT INTO "pending_inspections" ("payload","status","created_at") VALUES ('{ "hseFormId": "52e7ffdb-8812-40ea-9331-5360c165e6aa", "hseFormName": "Audit SMK3 (1)" }', 'NEW', 1781586828404);

