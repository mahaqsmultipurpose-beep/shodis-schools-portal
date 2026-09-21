// netlify/functions/students.js
//
// A small REST-style API for the Student Records module of the Uncle Shodis
// Schools portal, backed by Netlify Database (Postgres).
//
//   GET    /api/students            -> list all students
//   GET    /api/students?regNo=X    -> get one student
//   POST   /api/students            -> create or update a student (upsert by reg_no)
//   DELETE /api/students?regNo=X    -> delete a student
//
// Protected by a shared secret so casual visitors can't read/write data:
// the portal must send header "x-api-key" matching the PORTAL_API_KEY
// environment variable (set this in Netlify's site settings, never in code).
// This is a lightweight safeguard, not full per-user authentication — see
// the project README for what a fuller auth model would add.

import { getDatabase } from "@netlify/database";

const db = getDatabase();

function checkAuth(event) {
  const provided = event.headers["x-api-key"] || event.headers["X-Api-Key"];
  const expected = process.env.PORTAL_API_KEY;
  return expected && provided === expected;
}

function json(statusCode, body) {
  return new Response(JSON.stringify(body), {
    status: statusCode,
    headers: { "Content-Type": "application/json" },
  });
}

// Maps a database row (snake_case) to the shape the portal's JS already uses
// (camelCase matching its studentObj), so the frontend needs minimal changes.
function rowToStudent(row) {
  return {
    regNo: row.reg_no,
    lastName: row.last_name || "",
    firstName: row.first_name || "",
    otherNames: row.other_names || "",
    gender: row.gender || "",
    dob: row.dob || "",
    studentClass: row.student_class || "",
    session: row.session || "",
    term: row.term || "",
    phone: row.phone || "",
    email: row.email || "",
    enrollStatus: row.enroll_status || "Enrolled",
    enrollStatusDate: row.enroll_status_date || "",
    enrollStatusNotes: row.enroll_status_notes || "",
    photo: row.photo || "",
    subjects: row.subjects || [],
  };
}

export default async (req, context) => {
  const event = {
    httpMethod: req.method,
    headers: Object.fromEntries(req.headers),
  };
  const url = new URL(req.url);
  const regNoParam = url.searchParams.get("regNo");

  if (!checkAuth(event)) {
    return json(401, { error: "Unauthorized. Missing or invalid x-api-key." });
  }

  try {
    if (req.method === "GET") {
      if (regNoParam) {
        const rows = await db.sql`SELECT * FROM students WHERE reg_no = ${regNoParam}`;
        if (rows.length === 0) return json(404, { error: "Not found" });
        return json(200, rowToStudent(rows[0]));
      }
      const rows = await db.sql`SELECT * FROM students ORDER BY student_class, last_name`;
      return json(200, rows.map(rowToStudent));
    }

    if (req.method === "POST") {
      const s = await req.json();
      if (!s.regNo) return json(400, { error: "regNo is required" });

      const [row] = await db.sql`
        INSERT INTO students (
          reg_no, last_name, first_name, other_names, gender, dob, student_class,
          session, term, phone, email, enroll_status,
          enroll_status_date, enroll_status_notes, photo, subjects, updated_at
        ) VALUES (
          ${s.regNo}, ${s.lastName || ""}, ${s.firstName || ""}, ${s.otherNames || ""},
          ${s.gender || ""}, ${s.dob || ""}, ${s.studentClass || ""},
          ${s.session || ""}, ${s.term || ""}, ${s.phone || ""},
          ${s.email || ""}, ${s.enrollStatus || "Enrolled"},
          ${s.enrollStatusDate || ""}, ${s.enrollStatusNotes || ""}, ${s.photo || ""},
          ${JSON.stringify(s.subjects || [])}::jsonb, NOW()
        )
        ON CONFLICT (reg_no) DO UPDATE SET
          last_name = EXCLUDED.last_name,
          first_name = EXCLUDED.first_name,
          other_names = EXCLUDED.other_names,
          gender = EXCLUDED.gender,
          dob = EXCLUDED.dob,
          student_class = EXCLUDED.student_class,
          session = EXCLUDED.session,
          term = EXCLUDED.term,
          phone = EXCLUDED.phone,
          email = EXCLUDED.email,
          enroll_status = EXCLUDED.enroll_status,
          enroll_status_date = EXCLUDED.enroll_status_date,
          enroll_status_notes = EXCLUDED.enroll_status_notes,
          photo = EXCLUDED.photo,
          subjects = EXCLUDED.subjects,
          updated_at = NOW()
        RETURNING *
      `;
      return json(200, rowToStudent(row));
    }

    if (req.method === "DELETE") {
      if (!regNoParam) return json(400, { error: "regNo query parameter is required" });
      await db.sql`DELETE FROM students WHERE reg_no = ${regNoParam}`;
      return json(200, { deleted: regNoParam });
    }

    return json(405, { error: "Method not allowed" });
  } catch (err) {
    console.error(err);
    return json(500, { error: "Server error", detail: String(err.message || err) });
  }
};

export const config = {
  path: "/api/students",
};
