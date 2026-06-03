const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { createCanvas, loadImage } = require('canvas');

const app = express();
app.use(cors());
app.use(express.json());

// ─── BASE DE DADOS ───────────────────────────────────────
const pool = new Pool({
  user: "pint",
  host: "100.105.58.22",
  database: "testes2",
  password: "pint26",
  port: 5432,
});



// ─── PASTAS DE UPLOAD ────────────────────────────────────
if (!fs.existsSync("./uploads")) fs.mkdirSync("./uploads");
if (!fs.existsSync("./uploads/candidaturas")) fs.mkdirSync("./uploads/candidaturas");

// ─── STORAGE MULTER ──────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "./uploads/candidaturas"),
  filename: (req, file, cb) => {
    const nome =
      Date.now() +
      "-" +
      Math.round(Math.random() * 1e9) +
      path.extname(file.originalname);
    cb(null, nome);
  },
});

const upload = multer({ storage });

app.use("/uploads", express.static("uploads"));

// ─────────────────────────────────────────────────────────
// FUNÇÃO AUXILIAR: CALCULAR PROGRESSO DO BADGE
// ─────────────────────────────────────────────────────────
async function calcularProgressoBadge(client, userId, badgeId, idCandidatura) {
  const totalReqResult = await client.query(
    `
    SELECT COUNT(*)::int AS total
    FROM requisitos
    WHERE idbadge = $1
      AND ativo = TRUE
    `,
    [badgeId]
  );

  const progressoTotal = totalReqResult.rows[0]?.total ?? 0;

  const progressoAtualResult = await client.query(
    `
    SELECT COUNT(DISTINCT cr.idrequisito)::int AS total
    FROM candidaturasrequisitos cr
    INNER JOIN evidencias e
      ON e.idcandidaturareq = cr.idcandidaturareq
    INNER JOIN requisitos r
      ON r.idrequisito = cr.idrequisito
    WHERE cr.idcandidatura = $1
      AND r.idbadge = $2
      AND r.ativo = TRUE
    `,
    [idCandidatura, badgeId]
  );

  const progressoAtual = progressoAtualResult.rows[0]?.total ?? 0;
  const submetido = progressoTotal > 0 && progressoAtual >= progressoTotal;
  const estadoVisual = submetido
    ? "Submetido"
    : `${progressoAtual}/${progressoTotal}`;

  await client.query(
    `
    UPDATE candidaturasbadge
    SET progresso_atual = $2,
        progresso_total = $3,
        estado = 'SUBMITTED',
        datasubmissao = NOW()
    WHERE idcandidatura = $1
    `,
    [idCandidatura, progressoAtual, progressoTotal]
  );

  return {
    progressoAtual,
    progressoTotal,
    submetido,
    estadoVisual,
  };
}

// ─────────────────────────────────────────────────────────
// ÁREAS
// ─────────────────────────────────────────────────────────

app.get("/areas", async (req, res) => {
  try {
    const result = await pool.query("SELECT idarea, nome, descricao FROM areas WHERE ativo = TRUE ORDER BY nome ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar áreas:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/debug/areas", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM areas");
    res.json({ 
      total: result.rows.length,
      areas: result.rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/niveis", async (req, res) => {
  try {
    const result = await pool.query("SELECT idnivel, nome, descricao FROM nivel ORDER BY idnivel ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao carregar níveis:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// SERVICELINE
// ─────────────────────────────────────────────────────────
app.get("/serviceline", async (req, res) => {
  try {
    const result = await pool.query("SELECT idserviceline, nome, descricao FROM serviceline WHERE ativo = TRUE ORDER BY nome ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar serviceline:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/debug/serviceline", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM serviceline");
    res.json({ 
      total: result.rows.length,
      serviceline: result.rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// ÁREAS
// ─────────────────────────────────────────────────────────────

app.get("/areas", async (req, res) => {
  try {
    const result = await pool.query("SELECT idarea, nome, descricao FROM areas WHERE ativo = TRUE ORDER BY nome ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar áreas:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/debug/areas", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM areas");
    res.json({ 
      total: result.rows.length,
      areas: result.rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/niveis", async (req, res) => {
  try {
    const result = await pool.query("SELECT idnivel, nome, descricao FROM nivel ORDER BY idnivel ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao carregar níveis:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────
// ESPECIAIS
// ─────────────────────────────────────────────────────────────
app.get("/especiais", async (req, res) => {
  try {
    const result = await pool.query("SELECT idespecial, nome, descricao FROM especial WHERE ativo = TRUE ORDER BY nome ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar especiais:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────
// SERVICELINE
// ─────────────────────────────────────────────────────────────
app.get("/serviceline", async (req, res) => {
  try {
    const result = await pool.query("SELECT idserviceline, nome, descricao FROM serviceline WHERE ativo = TRUE ORDER BY nome ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar serviceline:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/debug/serviceline", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM serviceline");
    res.json({ 
      total: result.rows.length,
      serviceline: result.rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────
// BADGES
// ─────────────────────────────────────────────────────────────
app.get("/badges", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM badges ORDER BY idbadge ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar badges:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/badges/recomendados/:userId", async (req, res) => {
  try {
    const userId = parseInt(req.params.userId, 10);

    if (isNaN(userId)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    const userResult = await pool.query(
      "SELECT idarea FROM utilizadores WHERE idutilizador = $1",
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }

    const idArea = userResult.rows[0].idarea;

    if (!idArea) {
      return res.json([]);
    }

    const result = await pool.query(
      `
      SELECT b.*
      FROM badges b
      WHERE b.idarea = $1
      ORDER BY b.idbadge ASC
      `,
      [idArea]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar badges recomendados:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// RECOMENDAÇÕES PERSONALIZADAS POR UTILIZADOR
// Lógica: próximo nível baseado no maior nível já feito.
// Exclui badges com qualquer candidatura existente (independente do estado).
// ─────────────────────────────────────────────────────────
app.get("/utilizadores/:id/recomendacoes", async (req, res) => {
  try {
    const idUtilizador = parseInt(req.params.id, 10);
    if (isNaN(idUtilizador)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    // Área do utilizador
    const userResult = await pool.query(
      "SELECT idarea FROM utilizadores WHERE idutilizador = $1",
      [idUtilizador]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }
    const idArea = userResult.rows[0].idarea;
    if (!idArea) return res.json([]);

    // Nível máximo existente na BD
    const highestNivelRes = await pool.query(
      "SELECT MAX(idnivel)::int as maxnivel FROM nivel"
    );
    const highestNivel = highestNivelRes.rows[0]?.maxnivel ?? 1;

    // Maior nível que o utilizador já tem candidatura (qualquer estado)
    const userMaxNivelRes = await pool.query(
      `SELECT MAX(b.idnivel)::int as maxnivel
       FROM candidaturasbadge cb
       INNER JOIN badges b ON b.idbadge = cb.badge_id
       WHERE cb.user_id = $1`,
      [idUtilizador]
    );
    let userMaxNivel = userMaxNivelRes.rows[0]?.maxnivel ?? 1;

    // Próximo nível preferido: se já está no máximo, fica no mesmo
    const nextNivel = userMaxNivel < highestNivel
      ? userMaxNivel + 1
      : userMaxNivel;

    // Verificar se ainda há badges disponíveis no nextNivel (sem candidatura)
    const nextNivelDispRes = await pool.query(
      `SELECT COUNT(*)::int as total
       FROM badges b
       WHERE b.idarea = $1 AND b.idnivel = $2 AND b.ativo = TRUE
         AND NOT EXISTS (
           SELECT 1 FROM candidaturasbadge cb2
           WHERE cb2.user_id = $3 AND cb2.badge_id = b.idbadge
         )`,
      [idArea, nextNivel, idUtilizador]
    );
    const nextNivelDisp = nextNivelDispRes.rows[0]?.total ?? 0;

    // Se não há nada no próximo nível, cai de volta para o nível atual
    const preferredNivel = nextNivelDisp > 0 ? nextNivel : userMaxNivel;
    const secondaryNivel = preferredNivel === nextNivel ? userMaxNivel : nextNivel;

    const result = await pool.query(
      `SELECT
         b.*, n.nome AS nivel,
         COALESCE(cb.progresso_atual, 0) AS progresso_atual,
         COALESCE(cb.progresso_total, (
           SELECT COUNT(*) FROM requisitos r
           WHERE r.idbadge = b.idbadge AND r.ativo = TRUE
         )) AS progresso_total
       FROM badges b
       LEFT JOIN nivel n ON n.idnivel = b.idnivel
       LEFT JOIN candidaturasbadge cb ON cb.badge_id = b.idbadge AND cb.user_id = $1
       WHERE b.idarea = $2
         AND b.ativo = TRUE
         AND NOT EXISTS (
           SELECT 1 FROM candidaturasbadge cb2
           WHERE cb2.user_id = $1 AND cb2.badge_id = b.idbadge
         )
       ORDER BY
         CASE
           WHEN b.idnivel = $3 THEN 0
           WHEN b.idnivel = $4 THEN 1
           ELSE 2
         END,
         b.idnivel DESC,
         b.pontos DESC`,
      [idUtilizador, idArea, preferredNivel, secondaryNivel]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar recomendações:", err.message);
    res.status(500).json({ error: err.message });
  }
});



// Página pública HTML — badge individual (para assinatura / LinkedIn)
app.get("/badge/:id", async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) return res.status(400).send("ID inválido");

    const result = await pool.query(
      `SELECT b.*, n.nome as nivel_nome, a.nome as area_nome
       FROM badges b
       LEFT JOIN nivel n ON n.idnivel = b.idnivel
       LEFT JOIN areas a ON a.idarea = b.idarea
       WHERE b.idbadge = $1`,
      [id]
    );
    if (result.rows.length === 0) return res.status(404).send("Badge não encontrado");

    const b = result.rows[0];
    const imgTag = b.imagemurl
      ? `<img src="${b.imagemurl}" alt="${b.nome}" class="badge-img" onerror="this.style.display='none'">`
      : `<div class="badge-placeholder">🏆</div>`;

    res.setHeader("Content-Type", "text/html");
    res.send(`<!DOCTYPE html>
<html lang="pt">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta property="og:title" content="${b.nome} — Softinsa Talent">
  <meta property="og:description" content="${b.descricao || ''}">
  <title>${b.nome} — Softinsa Talent</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',sans-serif;background:#F0F4FF;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px}
    .card{background:#fff;border-radius:20px;padding:40px 32px;max-width:460px;width:100%;box-shadow:0 8px 32px rgba(0,0,0,.10);text-align:center}
    .logo{font-size:26px;font-weight:800;letter-spacing:2px;color:#1E3A5F;margin-bottom:28px}
    .logo span{color:#38BDF8}
    .badge-img{width:120px;height:120px;object-fit:contain;border-radius:16px;background:#F0F4FF;padding:12px}
    .badge-placeholder{font-size:80px;line-height:1}
    h1{font-size:22px;font-weight:800;color:#1E3A5F;margin:18px 0 8px}
    .desc{font-size:14px;color:#555;line-height:1.6;margin-bottom:20px}
    .tags{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-bottom:24px}
    .tag{background:#EFF6FF;color:#2563EB;font-size:12px;font-weight:600;padding:4px 12px;border-radius:20px}
    .tag.nivel{background:#FFF7ED;color:#EA580C}
    .tag.pts{background:#F0FDF4;color:#16A34A}
    .divider{border:none;border-top:1px solid #E5E7EB;margin:20px 0}
    .softinsa-link{display:inline-flex;align-items:center;gap:6px;color:#2563EB;font-size:14px;font-weight:600;text-decoration:none}
    .softinsa-link:hover{text-decoration:underline}
    .footer{font-size:11px;color:#9CA3AF;margin-top:16px}
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">SOF<span>T</span>INSA</div>
    ${imgTag}
    <h1>${b.nome}</h1>
    <p class="desc">${b.descricao || ''}</p>
    <div class="tags">
      ${b.area_nome ? `<span class="tag">${b.area_nome}</span>` : ''}
      ${b.nivel_nome ? `<span class="tag nivel">${b.nivel_nome}</span>` : ''}
      ${b.pontos ? `<span class="tag pts">🏅 ${b.pontos} pts</span>` : ''}
    </div>
    <hr class="divider">
    <a href="https://www.softinsa.pt" target="_blank" class="softinsa-link">
      🌐 softinsa.pt
    </a>
    <div class="footer">Softinsa Talent Management</div>
  </div>
</body>
</html>`);
  } catch (err) {
    res.status(500).send("Erro interno do servidor");
  }
});

app.get("/badges/:id", async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) return res.status(400).json({ error: "ID inválido" });

    const result = await pool.query(
      `SELECT b.*, n.nome as nivel_nome, a.nome as area_nome
       FROM badges b
       LEFT JOIN nivel n ON n.idnivel = b.idnivel
       LEFT JOIN areas a ON a.idarea = b.idarea
       WHERE b.idbadge = $1`,
      [id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: "Badge não encontrado" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Erro ao buscar badge:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/badges/:id/requisitos", async (req, res) => {
  try {
    const badgeId = parseInt(req.params.id, 10);

    if (isNaN(badgeId)) {
      return res.status(400).json({ error: "ID do badge inválido" });
    }

    const result = await pool.query(
      `
      SELECT
        idrequisito,
        idbadge,
        codigo,
        titulo,
        descricao,
        imagemurl,
        ordem,
        ativo,
        datacriacao,
        ultimaatualizacao
      FROM requisitos
      WHERE idbadge = $1
        AND ativo = TRUE
      ORDER BY ordem ASC, idrequisito ASC
      `,
      [badgeId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao carregar requisitos:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// CANDIDATURAS
// ─────────────────────────────────────────────────────────
app.get("/utilizadores/:id/candidaturas", async (req, res) => {
  try {
    const idUtilizador = parseInt(req.params.id, 10);

    if (isNaN(idUtilizador)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    const result = await pool.query(`
      SELECT
        cb.idcandidatura,
        cb.user_id,
        cb.badge_id,
        cb.estado,
        cb.datasubmissao,
        cb.comentariogeral,
        cb.datacriacao,
        cb.progresso_atual,
        cb.progresso_total,
        CASE
          WHEN cb.progresso_total > 0
           AND cb.progresso_atual >= cb.progresso_total
            THEN 'Submetido'
          ELSE CONCAT(cb.progresso_atual, '/', cb.progresso_total)
        END AS estado_visual,
        b.idbadge,
        b.nome,
        b.descricao,
        b.imagemurl,
        b.idnivel,
        b.pontos,
        b.linkpublicobase,
        b.competencias,
        b.certificado
      FROM candidaturasbadge cb
      INNER JOIN badges b ON b.idbadge = cb.badge_id
      WHERE cb.user_id = $1
      ORDER BY cb.datacriacao DESC
    `, [idUtilizador]);

    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao carregar candidaturas:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/candidaturas", upload.any(), async (req, res) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const userId = parseInt(req.body.user_id, 10);
    const badgeId = parseInt(req.body.badge_id, 10);

    if (isNaN(userId) || isNaN(badgeId)) {
      await client.query("ROLLBACK");
      return res.status(400).json({ error: "user_id ou badge_id inválido" });
    }

    const files = req.files || [];
    if (!files.length) {
      await client.query("ROLLBACK");
      return res.status(400).json({ error: "Nenhum ficheiro enviado" });
    }

    const totalReqResult = await client.query(
      `
      SELECT COUNT(*)::int AS total
      FROM requisitos
      WHERE idbadge = $1
        AND ativo = TRUE
      `,
      [badgeId]
    );

    const progressoTotal = totalReqResult.rows[0]?.total ?? 0;

    const candidaturaExistente = await client.query(
      `
      SELECT idcandidatura
      FROM candidaturasbadge
      WHERE user_id = $1 AND badge_id = $2
      LIMIT 1
      `,
      [userId, badgeId]
    );

    let idCandidatura;

    if (candidaturaExistente.rows.length > 0) {
      idCandidatura = candidaturaExistente.rows[0].idcandidatura;

      await client.query(
        `
        UPDATE candidaturasbadge
        SET estado = 'SUBMITTED',
            datasubmissao = NOW(),
            progresso_total = $2
        WHERE idcandidatura = $1
        `,
        [idCandidatura, progressoTotal]
      );
    } else {
      const candidaturaResult = await client.query(
        `
        INSERT INTO candidaturasbadge
        (user_id, badge_id, estado, datasubmissao, datacriacao, progresso_atual, progresso_total)
        VALUES ($1, $2, 'SUBMITTED', NOW(), NOW(), 0, $3)
        RETURNING idcandidatura
        `,
        [userId, badgeId, progressoTotal]
      );

      idCandidatura = candidaturaResult.rows[0].idcandidatura;
    }

    for (const file of files) {
      const fieldName = file.fieldname;
      const index = fieldName.split("_")[1];
      const requisitoId = parseInt(req.body[`requisito_id_${index}`], 10);

      if (isNaN(requisitoId)) continue;

      const candReqExistente = await client.query(
        `
        SELECT idcandidaturareq
        FROM candidaturasrequisitos
        WHERE idcandidatura = $1 AND idrequisito = $2
        LIMIT 1
        `,
        [idCandidatura, requisitoId]
      );

      let idCandidaturaReq;

      if (candReqExistente.rows.length > 0) {
        idCandidaturaReq = candReqExistente.rows[0].idcandidaturareq;

        await client.query(
          `
          DELETE FROM evidencias
          WHERE idcandidaturareq = $1
          `,
          [idCandidaturaReq]
        );
      } else {
        const candReqResult = await client.query(
          `
          INSERT INTO candidaturasrequisitos
          (idcandidatura, idrequisito)
          VALUES ($1, $2)
          RETURNING idcandidaturareq
          `,
          [idCandidatura, requisitoId]
        );

        idCandidaturaReq = candReqResult.rows[0].idcandidaturareq;
      }

      await client.query(
        `
        INSERT INTO evidencias
        (idcandidaturareq, ficheirourl, descricao, dataupload)
        VALUES ($1, $2, $3, NOW())
        `,
        [
          idCandidaturaReq,
          `http://100.105.58.22:3000/uploads/candidaturas/${file.filename}`,
          file.originalname,
        ]
      );
    }

    const progresso = await calcularProgressoBadge(
      client,
      userId,
      badgeId,
      idCandidatura
    );

    await client.query("COMMIT");

    res.status(200).json({
      success: true,
      message: "Candidatura submetida com sucesso",
      idcandidatura: idCandidatura,
      progresso_atual: progresso.progressoAtual,
      progresso_total: progresso.progressoTotal,
      estado_visual: progresso.estadoVisual,
      submetido: progresso.submetido,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("Erro ao submeter candidatura:", err.message);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// ─────────────────────────────────────────────────────────
// UTILIZADORES
// ─────────────────────────────────────────────────────────
app.get("/utilizadores", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT idutilizador, nome, email, fotourl, pontos, datacriacao FROM utilizadores ORDER BY idutilizador ASC"
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar utilizadores:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// GET: RANKING (ANTES de :id para evitar conflito)
// ─────────────────────────────────────────────────────────
app.get("/utilizadores/ranking", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        idutilizador,
        nome,
        email,
        COALESCE(fotourl, '') as fotourl,
        COALESCE(pontos, 0)::int as pontos
      FROM utilizadores
      WHERE nome IS NOT NULL
      ORDER BY COALESCE(pontos, 0) DESC, nome ASC
    `);
    
    if (result.rows.length === 0) {
      return res.json([]);
    }
    
    const rankingValido = result.rows.map(row => ({
      idutilizador: row.idutilizador,
      nome: row.nome || "Sem nome",
      email: row.email || "",
      fotourl: row.fotourl || "",
      pontos: parseInt(row.pontos) || 0
    }));
    
    res.json(rankingValido);
  } catch (err) {
    res.status(500).json({ 
      error: "Erro ao carregar ranking",
      details: err.message 
    });
  }
});

// ─────────────────────────────────────────────────────────
// GET: UTILIZADOR ESPECÍFICO (por ID) - Inclui todos os dados
// ─────────────────────────────────────────────────────────
app.get("/utilizadores/:id", async (req, res) => {
  try {
    const idutilizador = parseInt(req.params.id, 10);

    if (isNaN(idutilizador)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    const result = await pool.query(
      `SELECT 
        u.idutilizador,
        u.nome,
        u.email,
        u.fotourl,
        u.pontos,
        u.idarea,
        u.idrole,
        u.estadoconta,
        u.datacriacao,
        a.nome as area_nome
      FROM utilizadores u
      LEFT JOIN areas a ON u.idarea = a.idarea
      WHERE u.idutilizador = $1`,
      [idutilizador]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Erro ao buscar utilizador:", err.message);
    res.status(500).json({ error: err.message });
  }
});
app.get("/utilizadores/:id/badges", async (req, res) => {
  try {
    const idUtilizador = parseInt(req.params.id, 10);

    if (isNaN(idUtilizador)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    const result = await pool.query(
      `
      SELECT
        b.*,
        COALESCE(cb.progresso_atual, 0) as progresso_atual,
        COALESCE(cb.progresso_total, requisitos_count.total) as progresso_total,
        CASE
          WHEN COALESCE(cb.progresso_atual, 0) >= requisitos_count.total AND requisitos_count.total > 0
            THEN TRUE ELSE FALSE
        END as conquistado,
        cb.datasubmissao as data_conquista,
        COALESCE(cb.datacriacao, NOW()) as created_at,
        COALESCE(cb.datasubmissao, NOW()) as updated_at,
        cb.estado,
        cb.datasubmissao,
        CASE
          WHEN COALESCE(cb.progresso_atual, 0) >= COALESCE(cb.progresso_total, requisitos_count.total)
          AND requisitos_count.total > 0
            THEN 'Submetido'
          ELSE CONCAT(COALESCE(cb.progresso_atual, 0), '/', COALESCE(cb.progresso_total, requisitos_count.total))
        END AS estado_visual
      FROM badges b
      LEFT JOIN candidaturasbadge cb ON cb.badge_id = b.idbadge AND cb.user_id = $1
      LEFT JOIN LATERAL (
        SELECT COUNT(*)::int as total
        FROM requisitos
        WHERE idbadge = b.idbadge AND ativo = TRUE
      ) requisitos_count ON true
      ORDER BY b.idbadge ASC
      `,
      [idUtilizador]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar badges do utilizador:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.patch("/utilizadores/:id/foto", upload.single("foto"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "Nenhuma imagem enviada" });
    }

    const fotoUrl = `http://100.105.58.22:3000/uploads/candidaturas/${req.file.filename}`;

    await pool.query(
      "UPDATE utilizadores SET fotourl = $1 WHERE idutilizador = $2",
      [fotoUrl, req.params.id]
    );

    res.json({ success: true, fotourl: fotoUrl });
  } catch (err) {
    console.error("Erro ao atualizar foto:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// NOVO: Atualizar foto com BASE64 (direto na BD, sem ficheiros)
// ─────────────────────────────────────────────────────────
app.patch("/utilizadores/:id/foto-base64", async (req, res) => {
  try {
    const { foto_base64 } = req.body;
    
    if (!foto_base64) {
      return res.status(400).json({ error: "Foto base64 não fornecida" });
    }

    // Validar se é realmente base64
    if (!/^[A-Za-z0-9+/=]+$/.test(foto_base64)) {
      return res.status(400).json({ error: "Base64 inválido" });
    }

    // Armazenar base64 direto na coluna 'fotourl'
    await pool.query(
      "UPDATE utilizadores SET fotourl = $1 WHERE idutilizador = $2",
      [foto_base64, req.params.id]
    );

    res.json({ 
      success: true, 
      foto_base64: foto_base64 
    });
  } catch (err) {
    console.error("Erro ao atualizar foto base64:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// DIAGNÓSTICO: Testar conexão à BD
app.get("/debug/ping", async (req, res) => {
  try {
    const result = await pool.query("SELECT 1 as teste");
    res.json({ status: "OK", message: "Conexão à BD funcionando" });
  } catch (err) {
    res.status(500).json({ 
      status: "ERRO", 
      message: err.message 
    });
  }
});

// DIAGNÓSTICO: Ver quantos utilizadores existem
app.get("/debug/utilizadores-count", async (req, res) => {
  try {
    const result = await pool.query("SELECT COUNT(*) as total FROM utilizadores");
    res.json({ total: result.rows[0].total });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DIAGNÓSTICO: Ver todos os IDs
app.get("/debug/utilizadores-ids", async (req, res) => {
  try {
    const result = await pool.query("SELECT idutilizador, nome, pontos FROM utilizadores ORDER BY pontos DESC");
    console.log(`Utilizadores carregados: ${result.rows.length} registos`);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch("/utilizadores/:id/rgpd", async (req, res) => {
  try {
    const idUtilizador = parseInt(req.params.id, 10);
    const { rgpd } = req.body;

    if (isNaN(idUtilizador)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    const result = await pool.query(
      `
      UPDATE utilizadores
      SET rgpd = $1
      WHERE idutilizador = $2
      RETURNING idutilizador, nome, email, fotourl, pontos, rgpd
      `,
      [rgpd === true, idUtilizador]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }

    res.json({
      success: true,
      utilizador: result.rows[0],
    });
  } catch (err) {
    console.error("Erro ao atualizar RGPD:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────────────────────
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email e password são obrigatórios" });
  }

  try {
    const result = await pool.query(
      `SELECT u.*, a.nome as area_nome
       FROM utilizadores u
       LEFT JOIN areas a ON u.idarea = a.idarea
       WHERE u.email = $1`,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Email ou password incorretos" });
    }

    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.passwordhash);

    if (!match) {
      return res.status(401).json({ error: "Email ou password incorretos" });
    }

    const { passwordhash, ...userSemHash } = user;
    res.json({ success: true, utilizador: userSemHash });
  } catch (err) {
    console.error("Erro no login:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/registro", async (req, res) => {
  const { nome, email, password, idarea } = req.body;

  if (!nome || !email || !password) {
    return res
      .status(400)
      .json({ error: "Nome, email e password são obrigatórios" });
  }

  try {
    const existe = await pool.query(
      "SELECT idutilizador FROM utilizadores WHERE email = $1",
      [email]
    );

    if (existe.rows.length > 0) {
      return res.status(409).json({ error: "Este email já está registado" });
    }

    const hash = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO utilizadores
        (nome, email, passwordhash, idrole, idarea, emailconfirmado, primeirologin, estadoconta, datacriacao, pontos)
       VALUES ($1, $2, $3, 1, $4, FALSE, TRUE, 'ATIVA', NOW(), 0)
       RETURNING idutilizador, nome, email, fotourl, idarea, pontos, datacriacao`,
      [nome, email, hash, idarea || null]
    );

    res.status(201).json({ success: true, utilizador: result.rows[0] });
  } catch (err) {
    console.error("Erro no registro:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/alterar-password", async (req, res) => {
  const { idutilizador, passwordAtual, passwordNova } = req.body;

  if (!idutilizador || !passwordAtual || !passwordNova) {
    return res.status(400).json({
      error: "idutilizador, passwordAtual e passwordNova são obrigatórios",
    });
  }

  if (String(passwordNova).length < 6) {
    return res.status(400).json({
      error: "A nova password deve ter pelo menos 6 caracteres",
    });
  }

  try {
    const result = await pool.query(
      "SELECT * FROM utilizadores WHERE idutilizador = $1",
      [idutilizador]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }

    const user = result.rows[0];
    const match = await bcrypt.compare(passwordAtual, user.passwordhash);

    if (!match) {
      return res.status(401).json({ error: "A password atual está incorreta" });
    }

    const novoHash = await bcrypt.hash(passwordNova, 10);

    await pool.query(
      "UPDATE utilizadores SET passwordhash = $1, primeirologin = FALSE WHERE idutilizador = $2",
      [novoHash, idutilizador]
    );

    res.json({
      success: true,
      message: "Password alterada com sucesso",
    });
  } catch (err) {
    console.error("Erro ao alterar password:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post("/logout", (req, res) => {
  res.json({ success: true, message: "Sessão terminada" });
});

// ─────────────────────────────────────────────────────────
// NOTIFICAÇÕES
// ─────────────────────────────────────────────────────────
app.get("/notificacoes", async (req, res) => {
  const idutilizador = req.query.idutilizador ?? 1;

  try {
    const result = await pool.query(
      "SELECT * FROM notificacoes WHERE idutilizador = $1 ORDER BY dataenvio DESC",
      [idutilizador]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar notificações:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.patch("/notificacoes/marcar-todas", async (req, res) => {
  const idutilizador = req.query.idutilizador ?? 1;

  try {
    await pool.query(
      "UPDATE notificacoes SET lido = TRUE WHERE idutilizador = $1",
      [idutilizador]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("Erro ao marcar todas:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.patch("/notificacoes/:id/lida", async (req, res) => {
  try {
    await pool.query(
      "UPDATE notificacoes SET lido = TRUE WHERE idnotificacao = $1",
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("Erro ao marcar lida:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.delete("/notificacoes/:id", async (req, res) => {
  try {
    await pool.query(
      "DELETE FROM notificacoes WHERE idnotificacao = $1",
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("Erro ao apagar notificação:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// GERAR IMAGEM DO BADGE (para partilha no LinkedIn)
// POST /badges/:id/generate-image  body: { user_id: number }
// Aspeto igual ao card HTML de /badge/:id
// ─────────────────────────────────────────────────────────
app.post('/badges/:id/generate-image', async (req, res) => {
  const badgeId = parseInt(req.params.id, 10);
  const userId  = parseInt(req.body?.user_id, 10);

  if (isNaN(badgeId) || isNaN(userId)) {
    return res.status(400).json({ error: 'badge id e user_id são obrigatórios' });
  }

  try {
    const candCheck = await pool.query(
      'SELECT idcandidatura FROM candidaturasbadge WHERE user_id = $1 AND badge_id = $2 LIMIT 1',
      [userId, badgeId]
    );
    if (candCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Nenhuma candidatura encontrada' });
    }

    const badgeRes = await pool.query(
      `SELECT b.idbadge, b.nome, b.descricao, b.imagemurl, b.pontos,
              n.nome AS nivel_nome, a.nome AS area_nome
       FROM badges b
       LEFT JOIN nivel n ON n.idnivel = b.idnivel
       LEFT JOIN areas a ON a.idarea = b.idarea
       WHERE b.idbadge = $1`,
      [badgeId]
    );
    if (badgeRes.rows.length === 0) return res.status(404).json({ error: 'Badge não encontrado' });

    const b = badgeRes.rows[0];

    // ── Canvas 1200×630 (LinkedIn social card) ──
    const width = 1200, height = 630;
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');
    const cx = width / 2;

    // Helper: rectângulo com cantos arredondados
    function rr(x, y, w, h, r) {
      ctx.beginPath();
      ctx.moveTo(x + r, y);
      ctx.lineTo(x + w - r, y);
      ctx.arcTo(x + w, y,     x + w, y + r,     r);
      ctx.lineTo(x + w, y + h - r);
      ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
      ctx.lineTo(x + r, y + h);
      ctx.arcTo(x,     y + h, x,     y + h - r, r);
      ctx.lineTo(x,     y + r);
      ctx.arcTo(x,     y,     x + r, y,         r);
      ctx.closePath();
    }

    // ── Fundo #F0F4FF ──
    ctx.fillStyle = '#F0F4FF';
    ctx.fillRect(0, 0, width, height);

    // ── Sombra do card ──
    ctx.fillStyle = 'rgba(0,0,0,0.07)';
    rr(168, 38, 880, 570, 24); ctx.fill();

    // ── Card branco ──
    ctx.fillStyle = '#FFFFFF';
    rr(160, 30, 880, 570, 24); ctx.fill();

    // ── Logo SOFTINSA ──
    ctx.font = 'bold 46px Arial';
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'left';
    const logoChars  = ['S','O','F','T','I','N','S','A'];
    const logoColors = ['#1E3A5F','#1E3A5F','#1E3A5F','#38BDF8','#1E3A5F','#1E3A5F','#1E3A5F','#1E3A5F'];
    const totalLogoW = ctx.measureText('SOFTINSA').width;
    let lx = cx - totalLogoW / 2;
    for (let i = 0; i < logoChars.length; i++) {
      ctx.fillStyle = logoColors[i];
      ctx.fillText(logoChars[i], lx, 95);
      lx += ctx.measureText(logoChars[i]).width;
    }

    // ── Imagem do badge (caixa #F0F4FF arredondada) ──
    const imgBoxSize = 164, imgPad = 14;
    const imgBoxX = cx - imgBoxSize / 2, imgBoxY = 108;
    ctx.fillStyle = '#F0F4FF';
    rr(imgBoxX, imgBoxY, imgBoxSize, imgBoxSize, 16); ctx.fill();

    try {
      if (b.imagemurl) {
        const img = await loadImage(b.imagemurl);
        ctx.drawImage(img, imgBoxX + imgPad, imgBoxY + imgPad,
                          imgBoxSize - imgPad * 2, imgBoxSize - imgPad * 2);
      }
    } catch (_) {}

    // ── Nome do badge ──
    const nameY = imgBoxY + imgBoxSize + 46;
    ctx.fillStyle = '#1E3A5F';
    ctx.font = 'bold 34px Arial';
    ctx.textAlign = 'center';
    ctx.fillText(b.nome || '', cx, nameY);

    // ── Descrição (1 linha truncada) ──
    ctx.fillStyle = '#555555';
    ctx.font = '20px Arial';
    ctx.fillText((b.descricao || '').slice(0, 85), cx, nameY + 44);

    // ── Tags (área / nível / pontos) ──
    const tagDefs = [];
    if (b.area_nome) tagDefs.push({ text: b.area_nome,           bg: '#EFF6FF', color: '#2563EB' });
    if (b.nivel_nome) tagDefs.push({ text: b.nivel_nome,         bg: '#FFF7ED', color: '#EA580C' });
    if (b.pontos)     tagDefs.push({ text: `${b.pontos} pts`,    bg: '#F0FDF4', color: '#16A34A' });

    if (tagDefs.length > 0) {
      ctx.font = 'bold 18px Arial';
      const tagH = 36, tagPx = 22, tagGap = 14;
      const tagWidths = tagDefs.map(t => ctx.measureText(t.text).width + tagPx * 2);
      const totalTW = tagWidths.reduce((a, b) => a + b, 0) + tagGap * (tagDefs.length - 1);
      let tx = cx - totalTW / 2;
      const tagY = nameY + 92;
      for (let i = 0; i < tagDefs.length; i++) {
        ctx.fillStyle = tagDefs[i].bg;
        rr(tx, tagY, tagWidths[i], tagH, tagH / 2); ctx.fill();
        ctx.fillStyle = tagDefs[i].color;
        ctx.textAlign = 'center';
        ctx.fillText(tagDefs[i].text, tx + tagWidths[i] / 2, tagY + tagH * 0.72);
        tx += tagWidths[i] + tagGap;
      }
    }

    // ── Divisor ──
    ctx.strokeStyle = '#E5E7EB';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(240, nameY + 144);
    ctx.lineTo(960, nameY + 144);
    ctx.stroke();

    // ── Footer ──
    ctx.fillStyle = '#9CA3AF';
    ctx.font = '17px Arial';
    ctx.textAlign = 'center';
    ctx.fillText('Softinsa Talent Management', cx, 572);

    const base64str = canvas.toBuffer('image/png').toString('base64');

    // Guardar na BD para reutilização
    try {
      await pool.query('ALTER TABLE candidaturasbadge ADD COLUMN IF NOT EXISTS badge_image_base64 TEXT');
      await pool.query(
        'UPDATE candidaturasbadge SET badge_image_base64 = $1 WHERE idcandidatura = $2',
        [base64str, candCheck.rows[0].idcandidatura]
      );
    } catch (e) {
      console.warn('Não foi possível guardar imagem na BD:', e.message);
    }

    return res.json({ base64: base64str });
  } catch (err) {
    console.error('Erro ao gerar imagem do badge:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// START
// ─────────────────────────────────────────────────────────
app.listen(3000, "0.0.0.0", () => {
  const c = {
    reset:   '\x1b[0m',
    bold:    '\x1b[1m',
    gray:    '\x1b[90m',
    cyan:    '\x1b[36m',
    green:   '\x1b[32m',
    yellow:  '\x1b[33m',
    blue:    '\x1b[34m',
    magenta: '\x1b[35m',
    red:     '\x1b[31m',
  };

  const sep = () => console.log(`  ${c.gray}${'─'.repeat(50)}${c.reset}`);

  const row = (num, method, path) => {
    const mc = { GET: c.green, POST: c.yellow, PATCH: c.blue, DELETE: c.red };
    const col = mc[method] || c.reset;
    console.log(`  ${c.gray}${String(num).padStart(2)}${c.reset}  ${col}${method.padEnd(7)}${c.reset}${path}`);
  };

  const section = (title) => {
    console.log('');
    console.log(`  ${c.bold}${title}${c.reset}`);
    sep();
  };

  console.log('');
  console.log(`${c.bold}${c.cyan}  ╔════════════════════════════════════════════════════╗${c.reset}`);
  console.log(`${c.bold}${c.cyan}  ║       SOFTINSA TALENT API — 0.0.0.0:3000          ║${c.reset}`);
  console.log(`${c.bold}${c.cyan}  ╚════════════════════════════════════════════════════╝${c.reset}`);

  section('AUTH');
  row( 1, 'POST',   '/login');
  row( 2, 'POST',   '/registro');
  row( 3, 'POST',   '/logout');
  row( 4, 'POST',   '/alterar-password');

  section('UTILIZADORES');
  row( 5, 'GET',    '/utilizadores');
  row( 6, 'GET',    '/utilizadores/ranking');
  row( 7, 'GET',    '/utilizadores/:id');
  row( 8, 'GET',    '/utilizadores/:id/badges');
  row( 9, 'GET',    '/utilizadores/:id/candidaturas');
  row(10, 'PATCH',  '/utilizadores/:id/foto');
  row(11, 'PATCH',  '/utilizadores/:id/foto-base64');
  row(12, 'PATCH',  '/utilizadores/:id/rgpd');

  section('BADGES');
  row(13, 'GET',    '/badges');
  row(14, 'GET',    '/badges/recomendados/:userId');
  row(15, 'GET',    '/badges/:id');
  row(16, 'GET',    '/badges/:id/requisitos');
  row(17, 'GET',    '/badge/:id  (HTML público)');

  section('CANDIDATURAS');
  row(18, 'POST',   '/candidaturas');

  section('CATÁLOGO');
  row(19, 'GET',    '/areas');
  row(20, 'GET',    '/niveis');
  row(21, 'GET',    '/especiais');
  row(22, 'GET',    '/serviceline');

  section('NOTIFICAÇÕES');
  row(23, 'GET',    '/notificacoes');
  row(24, 'PATCH',  '/notificacoes/marcar-todas');
  row(25, 'PATCH',  '/notificacoes/:id/lida');
  row(26, 'DELETE', '/notificacoes/:id');

  section(`${c.gray}DEBUG`);
  row(27, 'GET',    '/debug/ping');
  row(28, 'GET',    '/debug/areas');
  row(29, 'GET',    '/debug/serviceline');
  row(30, 'GET',    '/debug/utilizadores-count');
  row(31, 'GET',    '/debug/utilizadores-ids');

  console.log('');
  console.log(`  ${c.green}${c.bold}✔  Servidor pronto!${c.reset}`);
  console.log('');
});