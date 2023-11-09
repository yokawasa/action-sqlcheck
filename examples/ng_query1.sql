SELECT a.ID FROM TableA a
WHERE EXISTS (
    SELECT *
    FROM TableB b
    WHERE b.ID = a.B_ID);
