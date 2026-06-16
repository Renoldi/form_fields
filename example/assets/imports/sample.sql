-- Sample SQL import for FormFields example
DROP TABLE IF EXISTS notes;
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT
);

INSERT INTO notes (title, body) VALUES ('Welcome', 'This is an imported note');
INSERT INTO notes (title, body) VALUES ('Second', 'Another imported note');
