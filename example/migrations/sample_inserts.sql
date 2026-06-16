-- Sample inserts (compatible with created tables). These provide demo rows
-- Asset: insert 5 assets (assetId is primary key)
INSERT INTO "asset" (assetId, payload, updated_at) VALUES (
  '97502c88-9703-4712-a957-1d0985b3db65-1',
  '{"assetId":"97502c88-9703-4712-a957-1d0985b3db65-1","assetNumber":"1","assetName":"laptop"}',
  1781586828000
);
INSERT INTO "asset" (assetId, payload, updated_at) VALUES (
  '97502c88-9703-4712-a957-1d0985b3db65-2',
  '{"assetId":"97502c88-9703-4712-a957-1d0985b3db65-2","assetNumber":"2","assetName":"laptop-2"}',
  1781586828001
);
INSERT INTO "asset" (assetId, payload, updated_at) VALUES (
  '97502c88-9703-4712-a957-1d0985b3db65-3',
  '{"assetId":"97502c88-9703-4712-a957-1d0985b3db65-3","assetNumber":"3","assetName":"laptop-3"}',
  1781586828002
);
INSERT INTO "asset" (assetId, payload, updated_at) VALUES (
  '97502c88-9703-4712-a957-1d0985b3db65-4',
  '{"assetId":"97502c88-9703-4712-a957-1d0985b3db65-4","assetNumber":"4","assetName":"laptop-4"}',
  1781586828003
);
INSERT INTO "asset" (assetId, payload, updated_at) VALUES (
  '97502c88-9703-4712-a957-1d0985b3db65-5',
  '{"assetId":"97502c88-9703-4712-a957-1d0985b3db65-5","assetNumber":"5","assetName":"laptop-5"}',
  1781586828004
);

-- master_inspection_forms: insert 5 forms (hseFormId is PK)
INSERT INTO "master_inspection_forms" (hseFormId, payload, updated_at) VALUES (
  'cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-1',
  '{"hseFormId":"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-1","hseFormName":"Pemeriksaan kendaraan"}',
  1781586828280
);
INSERT INTO "master_inspection_forms" (hseFormId, payload, updated_at) VALUES (
  'cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-2',
  '{"hseFormId":"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-2","hseFormName":"Pemeriksaan kendaraan 2"}',
  1781586828281
);
INSERT INTO "master_inspection_forms" (hseFormId, payload, updated_at) VALUES (
  'cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-3',
  '{"hseFormId":"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-3","hseFormName":"Pemeriksaan kendaraan 3"}',
  1781586828282
);
INSERT INTO "master_inspection_forms" (hseFormId, payload, updated_at) VALUES (
  'cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-4',
  '{"hseFormId":"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-4","hseFormName":"Pemeriksaan kendaraan 4"}',
  1781586828283
);
INSERT INTO "master_inspection_forms" (hseFormId, payload, updated_at) VALUES (
  'cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-5',
  '{"hseFormId":"cfab09ed-2fa0-4504-8b48-1446a6a9cfd1-5","hseFormName":"Pemeriksaan kendaraan 5"}',
  1781586828284
);

-- master_inspections: insert 5 masters (hseFormId is PK)
INSERT INTO "master_inspections" (hseFormId, payload, updated_at, formType) VALUES (
  '227460fb-8566-49c9-a128-ad431480602d-1',
  '{"hseFormId":"227460fb-8566-49c9-a128-ad431480602d-1","hseFormName":"Membersihkan telinga"}',
  1781586828300,
  'PROCESS'
);
INSERT INTO "master_inspections" (hseFormId, payload, updated_at, formType) VALUES (
  '227460fb-8566-49c9-a128-ad431480602d-2',
  '{"hseFormId":"227460fb-8566-49c9-a128-ad431480602d-2","hseFormName":"Membersihkan telinga 2"}',
  1781586828301,
  'PROCESS'
);
INSERT INTO "master_inspections" (hseFormId, payload, updated_at, formType) VALUES (
  '227460fb-8566-49c9-a128-ad431480602d-3',
  '{"hseFormId":"227460fb-8566-49c9-a128-ad431480602d-3","hseFormName":"Membersihkan telinga 3"}',
  1781586828302,
  'PROCESS'
);
INSERT INTO "master_inspections" (hseFormId, payload, updated_at, formType) VALUES (
  '227460fb-8566-49c9-a128-ad431480602d-4',
  '{"hseFormId":"227460fb-8566-49c9-a128-ad431480602d-4","hseFormName":"Membersihkan telinga 4"}',
  1781586828303,
  'PROCESS'
);
INSERT INTO "master_inspections" (hseFormId, payload, updated_at, formType) VALUES (
  '227460fb-8566-49c9-a128-ad431480602d-5',
  '{"hseFormId":"227460fb-8566-49c9-a128-ad431480602d-5","hseFormName":"Membersihkan telinga 5"}',
  1781586828304,
  'PROCESS'
);

-- pending_inspections: insert 5 pending rows (id autoincrement)
INSERT INTO "pending_inspections" (payload, status, created_at) VALUES (
  '{"hseFormId":"52e7ffdb-8812-40ea-9331-5360c165e6aa","hseFormName":"Audit SMK3 (1)"}', 'NEW', 1781586828400
);
INSERT INTO "pending_inspections" (payload, status, created_at) VALUES (
  '{"hseFormId":"52e7ffdb-8812-40ea-9331-5360c165e6aa","hseFormName":"Audit SMK3 (1)"}', 'NEW', 1781586828401
);
INSERT INTO "pending_inspections" (payload, status, created_at) VALUES (
  '{"hseFormId":"52e7ffdb-8812-40ea-9331-5360c165e6aa","hseFormName":"Audit SMK3 (1)"}', 'NEW', 1781586828402
);
INSERT INTO "pending_inspections" (payload, status, created_at) VALUES (
  '{"hseFormId":"52e7ffdb-8812-40ea-9331-5360c165e6aa","hseFormName":"Audit SMK3 (1)"}', 'NEW', 1781586828403
);
INSERT INTO "pending_inspections" (payload, status, created_at) VALUES (
  '{"hseFormId":"52e7ffdb-8812-40ea-9331-5360c165e6aa","hseFormName":"Audit SMK3 (1)"}', 'NEW', 1781586828404
);
