const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { createCanvas, loadImage } = require('canvas');
const PDFDocument = require('pdfkit');
require('dotenv').config();
const sgMail = require('@sendgrid/mail');
const { initializeApp: initializeFirebaseApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

// ─────────────────────────────────────────────────────────
// EMAIL (SendGrid via API HTTPS — SMTP de saída é bloqueado em muitos PaaS,
// incluindo o Render, daí usar uma API em vez de ligação SMTP direta)
// ─────────────────────────────────────────────────────────
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
} else {
  console.warn('SENDGRID_API_KEY não definida. Sets em .env para enviar emails.');
}

async function enviarEmail({ to, subject, html, text }) {
  if (!to || !process.env.SENDGRID_API_KEY) return;
  try {
    await sgMail.send({
      to,
      from: process.env.EMAIL_FROM || 'no-reply@example.com',
      subject,
      text: text || html?.replace(/<[^>]+>/g, ''),
      html,
    });
  } catch (err) {
    console.error('Erro ao enviar email:', err.response?.body?.errors || err.message);
  }
}

async function sendCandidaturaConfirmation(email, nome, badgeNome, idCandidatura) {
  if (!email) return;

  await enviarEmail({
    to: email,
    subject: `Confirmação de submissão da candidatura #${idCandidatura}`,
    html: `<p>Olá ${nome || ''},</p><p>Recebemos a sua candidatura para o badge "<strong>${badgeNome}</strong>".</p><p><strong>ID da candidatura:</strong> ${idCandidatura}</p><p>Obrigado,<br/>Equipa PINT</p>`,
  });
  console.log('Email de confirmação enviado para', email);
}
      
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

// Helper: verifica se uma tabela existe na BD (schema.public)
async function tableExists(tableName) {
  try {
    const result = await pool.query("SELECT to_regclass($1) as r", [tableName]);
    return result.rows[0] && result.rows[0].r !== null;
  } catch (err) {
    console.error("Erro ao verificar existência de tabela:", err.message);
    return false;
  }
}

// Garantir colunas para armazenar imagem do badge em candidaturasbadge
async function ensureBadgeImageColumns() {
  try {
    await pool.query("ALTER TABLE candidaturasbadge ADD COLUMN IF NOT EXISTS badge_image_base64 TEXT");
  } catch (err) {
    console.error('Erro ao garantir colunas badge_image:', err.message || err);
  }
}

// ─── PASTAS DE UPLOAD ────────────────────────────────────
if (!fs.existsSync("./uploads")) fs.mkdirSync("./uploads");
if (!fs.existsSync("./uploads/candidaturas")) fs.mkdirSync("./uploads/candidaturas");
if (!fs.existsSync("./uploads/badges")) fs.mkdirSync("./uploads/badges");

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

app.use(express.static("public"));
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
  // Note: we no longer write to `utilizador_badge` from the server.

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
// (Duplicate route blocks removed; first occurrences retained above.)

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
    if (!(await tableExists('public.badges'))) {
      // Tabela de badges não existe: retornar lista vazia para evitar crash na app
      return res.json([]);
    }
    const result = await pool.query(
      `SELECT b.*, n.nome AS nivel
       FROM badges b
       LEFT JOIN nivel n ON n.idnivel = b.idnivel
       ORDER BY b.idbadge ASC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar badges:", err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get("/badges/recomendados/:userId", async (req, res) => {
  try {
    if (!(await tableExists('public.badges'))) {
      // Se a tabela de badges não existir, devolve lista vazia
      return res.json([]);
    }

    const userId = parseInt(req.params.userId, 10);

    if (isNaN(userId)) {
      return res.status(400).json({ error: "ID do utilizador inválido" });
    }

    // Primeiro obter o idarea do utilizador
    const userResult = await pool.query(
      "SELECT idarea FROM utilizadores WHERE idutilizador = $1",
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: "Utilizador não encontrado" });
    }

    const idArea = userResult.rows[0].idarea;

    if (!idArea) {
      // Se o utilizador não tem área, retorna lista vazia
      return res.json([]);
    }

    // Determine highest nivel in DB
    const highestNivelRes = await pool.query("SELECT MAX(idnivel)::int as maxnivel FROM nivel");
    const highestNivel = highestNivelRes.rows[0]?.maxnivel ?? 1;

    // User's highest nivel already completed (consider submitted or fully progressed candidaturas)
    const userMaxNivelRes = await pool.query(
      `SELECT MAX(b.idnivel)::int as maxnivel
       FROM candidaturasbadge cb
       INNER JOIN badges b ON b.idbadge = cb.badge_id
       WHERE cb.user_id = $1
         AND (
           cb.estado = 'SUBMITTED' OR (cb.progresso_total > 0 AND cb.progresso_atual >= cb.progresso_total)
         )`,
      [userId]
    );

    let userMaxNivel = userMaxNivelRes.rows[0]?.maxnivel;
    if (!userMaxNivel) userMaxNivel = 1;

    // Preferred "next" level: if already at highest, prefer level below
    const nextNivel = userMaxNivel < highestNivel ? userMaxNivel + 1 : Math.max(1, userMaxNivel - 1);

    // Check whether the user has completed ALL badges in their current max nivel
    const totalBadgesRes = await pool.query(
      `SELECT COUNT(*)::int as total FROM badges WHERE idarea = $1 AND idnivel = $2 AND ativo = TRUE`,
      [idArea, userMaxNivel]
    );
    const totalBadgesThisNivel = totalBadgesRes.rows[0]?.total ?? 0;

    const userCompletedCountRes = await pool.query(
      `SELECT COUNT(DISTINCT b.idbadge)::int as completed
       FROM candidaturasbadge cb
       INNER JOIN badges b ON b.idbadge = cb.badge_id
       WHERE cb.user_id = $1
         AND b.idarea = $2
         AND b.idnivel = $3
         AND (
           cb.estado = 'SUBMITTED' OR (cb.progresso_total > 0 AND cb.progresso_atual >= cb.progresso_total)
         )`,
      [userId, idArea, userMaxNivel]
    );
    const userCompletedThisNivel = userCompletedCountRes.rows[0]?.completed ?? 0;

    // If user completed all badges in this nivel, prefer the nextNivel; otherwise keep current nivel as preferred
    const allCompletedThisNivel = totalBadgesThisNivel > 0 && userCompletedThisNivel >= totalBadgesThisNivel;
    let preferredNivel = allCompletedThisNivel ? nextNivel : userMaxNivel;
    // If preferred nivel has no recommendable badges (all excluded or none exist), fall back to current nivel
    const preferredAvailableRes = await pool.query(
      `SELECT COUNT(*)::int as total FROM badges b
       WHERE b.idarea = $1 AND b.idnivel = $2 AND b.ativo = TRUE
         AND NOT EXISTS (
           SELECT 1 FROM candidaturasbadge cb2
           WHERE cb2.user_id = $3
             AND cb2.badge_id = b.idbadge
             AND (
               cb2.estado = 'SUBMITTED' OR (cb2.progresso_total > 0 AND cb2.progresso_atual >= cb2.progresso_total)
             )
         )`,
      [idArea, preferredNivel, userId]
    );
    const preferredAvailable = preferredAvailableRes.rows[0]?.total ?? 0;
    if (preferredAvailable === 0) {
      preferredNivel = userMaxNivel;
    }
    // secondary priority is the other one
    const secondaryNivel = preferredNivel === userMaxNivel ? nextNivel : userMaxNivel;

    const recomendQuery = `
      SELECT
        b.*, n.nome AS nivel,
        COALESCE(cb.progresso_atual, 0) as progresso_atual,
        COALESCE(cb.progresso_total, (
          SELECT COUNT(*) FROM requisitos r WHERE r.idbadge = b.idbadge AND r.ativo = TRUE
        )) as progresso_total
      FROM badges b
      LEFT JOIN nivel n ON n.idnivel = b.idnivel
      LEFT JOIN candidaturasbadge cb ON cb.badge_id = b.idbadge AND cb.user_id = $1
      WHERE b.idarea = $2
        AND NOT EXISTS (
          SELECT 1 FROM candidaturasbadge cb2
          WHERE cb2.user_id = $1
            AND cb2.badge_id = b.idbadge
            AND (
              cb2.estado = 'SUBMITTED' OR (cb2.progresso_total > 0 AND cb2.progresso_atual >= cb2.progresso_total)
            )
        )
      ORDER BY
        CASE
          WHEN b.idnivel = $3 THEN 0
          WHEN b.idnivel = $4 THEN 1
          WHEN b.idnivel < $3 THEN 2
          ELSE 3
        END,
        b.idnivel DESC,
        b.pontos DESC
    `;

    const recResult = await pool.query(recomendQuery, [userId, idArea, preferredNivel, secondaryNivel]);
    res.json(recResult.rows);
  } catch (err) {
    console.error("Erro ao buscar badges recomendados:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// RECOMENDAÇÕES PERSONALIZADAS POR UTILIZADOR
// Ordena por: mesmo nível do maior nível conquistado -> próximo nível -> níveis abaixo
// Exclui badges já conquistados (candidaturas completadas)
app.get("/utilizadores/:id/recomendacoes", async (req, res) => {
  try {
    const idUtilizador = parseInt(req.params.id, 10);
    if (isNaN(idUtilizador)) return res.status(400).json({ error: "ID do utilizador inválido" });

    // obter área do utilizador
    const userResult = await pool.query("SELECT idarea FROM utilizadores WHERE idutilizador = $1", [idUtilizador]);
    if (userResult.rows.length === 0) return res.status(404).json({ error: "Utilizador não encontrado" });
    const idArea = userResult.rows[0].idarea;
    if (!idArea) return res.json([]);

    // maior idnivel existente (limites)
    const highestNivelRes = await pool.query("SELECT MAX(idnivel)::int as maxnivel FROM nivel");
    const highestNivel = highestNivelRes.rows[0]?.maxnivel ?? 1;

    // maior nível que o utilizador já completou (candidaturas submetidas)
    const userMaxNivelRes = await pool.query(
      `SELECT MAX(b.idnivel)::int as maxnivel
       FROM candidaturasbadge cb
       INNER JOIN badges b ON b.idbadge = cb.badge_id
       WHERE cb.user_id = $1
         AND (
           cb.estado = 'SUBMITTED' OR (cb.progresso_total > 0 AND cb.progresso_atual >= cb.progresso_total)
         )`,
      [idUtilizador]
    );

    let userMaxNivel = userMaxNivelRes.rows[0]?.maxnivel;
    if (!userMaxNivel) userMaxNivel = 1;

    // calcular o 'próximo nível' preferido: se já no maior nível, preferir nível abaixo
    const nextNivel = userMaxNivel < highestNivel ? userMaxNivel + 1 : Math.max(1, userMaxNivel - 1);

    // Verificar se o utilizador completou TODOS os badges neste nivel
    const totalBadgesRes2 = await pool.query(
      `SELECT COUNT(*)::int as total FROM badges WHERE idarea = $1 AND idnivel = $2 AND ativo = TRUE`,
      [idArea, userMaxNivel]
    );
    const totalBadgesThisNivel2 = totalBadgesRes2.rows[0]?.total ?? 0;

    const userCompletedCountRes2 = await pool.query(
      `SELECT COUNT(DISTINCT b.idbadge)::int as completed
       FROM candidaturasbadge cb
       INNER JOIN badges b ON b.idbadge = cb.badge_id
       WHERE cb.user_id = $1
         AND b.idarea = $2
         AND b.idnivel = $3
         AND (
           cb.estado = 'SUBMITTED' OR (cb.progresso_total > 0 AND cb.progresso_atual >= cb.progresso_total)
         )`,
      [idUtilizador, idArea, userMaxNivel]
    );
    const userCompletedThisNivel2 = userCompletedCountRes2.rows[0]?.completed ?? 0;

    const allCompletedThisNivel2 = totalBadgesThisNivel2 > 0 && userCompletedThisNivel2 >= totalBadgesThisNivel2;
    let preferredNivel2 = allCompletedThisNivel2 ? nextNivel : userMaxNivel;
    // If preferred nivel has no recommendable badges, fall back to current nivel
    const preferredAvailableRes2 = await pool.query(
      `SELECT COUNT(*)::int as total FROM badges b
       WHERE b.idarea = $1 AND b.idnivel = $2 AND b.ativo = TRUE
         AND NOT EXISTS (
           SELECT 1 FROM candidaturasbadge cb2
           WHERE cb2.user_id = $3
             AND cb2.badge_id = b.idbadge
             AND (
               cb2.estado = 'SUBMITTED' OR (cb2.progresso_total > 0 AND cb2.progresso_atual >= cb2.progresso_total)
             )
         )`,
      [idArea, preferredNivel2, idUtilizador]
    );
    const preferredAvailable2 = preferredAvailableRes2.rows[0]?.total ?? 0;
    if (preferredAvailable2 === 0) {
      preferredNivel2 = userMaxNivel;
    }
    const secondaryNivel2 = preferredNivel2 === userMaxNivel ? nextNivel : userMaxNivel;

    const recomendQuery = `
      SELECT
        b.*, n.nome AS nivel,
        COALESCE(cb.progresso_atual, 0) as progresso_atual,
        COALESCE(cb.progresso_total, (
          SELECT COUNT(*) FROM requisitos r WHERE r.idbadge = b.idbadge AND r.ativo = TRUE
        )) as progresso_total
      FROM badges b
      LEFT JOIN nivel n ON n.idnivel = b.idnivel
      LEFT JOIN candidaturasbadge cb ON cb.badge_id = b.idbadge AND cb.user_id = $1
      WHERE b.idarea = $2
        AND NOT EXISTS (
          SELECT 1 FROM candidaturasbadge cb2
          WHERE cb2.user_id = $1
            AND cb2.badge_id = b.idbadge
            AND (
              cb2.estado = 'SUBMITTED' OR (cb2.progresso_total > 0 AND cb2.progresso_atual >= cb2.progresso_total)
            )
        )
      ORDER BY
        CASE
          WHEN b.idnivel = $3 THEN 0
          WHEN b.idnivel = $4 THEN 1
          WHEN b.idnivel < $3 THEN 2
          ELSE 3
        END,
        b.idnivel DESC,
        b.pontos DESC
    `;

    const recResult = await pool.query(recomendQuery, [idUtilizador, idArea, preferredNivel2, secondaryNivel2]);
    res.json(recResult.rows);
  } catch (err) {
    console.error("Erro ao buscar recomendacoes:", err.message);
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
    const badgesExist = await tableExists('public.badges');

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
        b.certificado,
        cb.certificado_pdf_base64,
        b.expiremeses
      FROM candidaturasbadge cb
      INNER JOIN badges b ON b.idbadge = cb.badge_id
      WHERE cb.user_id = $1
      ORDER BY cb.datacriacao DESC
    `, [idUtilizador]);

      res.json(result.rows);
    } else {
      // Fallback sem a tabela badges: devolve candidaturas sem os campos da tabela badges
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
          END AS estado_visual
        FROM candidaturasbadge cb
        WHERE cb.user_id = $1
        ORDER BY cb.datacriacao DESC
      `, [idUtilizador]);

      res.json(result.rows);
    }
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
// ───────────────────────────────────────────────────                          
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

    if (!(await tableExists('public.badges'))) {
      // Sem tabela de badges: não tentar fazer joins; devolve lista vazia
      return res.json([]);
    }

    // Return badges joined with candidaturasbadge only; do not query utilizador_badge.
    const result = await pool.query(
      `
      SELECT 
        b.*,
        cb.certificado_pdf_base64,
        COALESCE(cb.progresso_atual, 0) as progresso_atual,
        COALESCE(cb.progresso_total, requisitos_count.total) as progresso_total,
        FALSE as conquistado,
        NULL as data_conquista,
        NOW() as created_at,
        NOW() as updated_at,
        cb.estado,
        cb.datasubmissao,
        CASE
          WHEN COALESCE(cb.progresso_atual, 0) >= COALESCE(cb.progresso_total, requisitos_count.total) 
          AND requisitos_count.total > 0
            THEN 'Submetido'
          ELSE CONCAT(COALESCE(cb.progresso_atual, 0), '/', COALESCE(cb.progresso_total, requisitos_count.total))
        END AS estado_visual
      FROM badges b
      LEFT JOIN nivel n ON n.idnivel = b.idnivel
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
// START
// ─────────────────────────────────────────────────────────
// Garantir colunas e só depois iniciar o servidor
ensureBadgeImageColumns()
  .then(() => {
    app.listen(3000, "0.0.0.0", () => {
      console.log("Servidor a correr em http://0.0.0.0:3000");
    });
  })
  .catch((err) => {
    console.error('Erro ao garantir colunas ou iniciar servidor:', err.message || err);
    // Ainda tentamos iniciar o servidor mesmo se a garantia falhar
    app.listen(3000, "0.0.0.0", () => {
      console.log("Servidor a correr em http://0.0.0.0:3000 (com warnings)");
    });
  });

// ─────────────────────────────────────────────────────────
// GERA IMAGEM DO BADGE (badge + user info) -> retorna URL/png base64
// POST /badges/:id/generate-image  body: { user_id: number }
// ─────────────────────────────────────────────────────────
app.post('/badges/:id/generate-image', async (req, res) => {
  const badgeId = parseInt(req.params.id, 10);
  const userIdRaw = req.body?.user_id ?? req.query?.user_id;
  const userId = parseInt(userIdRaw, 10);

  if (isNaN(badgeId) || isNaN(userId)) {
    return res.status(400).json({ error: 'badge id and user_id are required' });
  }

  try {
    if (!(await tableExists('public.badges'))) {
      return res.status(404).json({ error: 'Tabela de badges não encontrada' });
    }
      // Antes de carregar dados e gerar a imagem, verificar se existe uma candidatura
      const candCheck = await pool.query(
        'SELECT idcandidatura FROM candidaturasbadge WHERE user_id = $1 AND badge_id = $2 LIMIT 1',
        [userId, badgeId]
      );

      if (candCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Nenhuma candidatura encontrada para este utilizador e badge' });
      }

      // load badge and user
      const badgeRes = await pool.query('SELECT idbadge, nome, descricao, imagemurl FROM badges WHERE idbadge = $1', [badgeId]);
      const userRes = await pool.query('SELECT idutilizador, nome, fotourl FROM utilizadores WHERE idutilizador = $1', [userId]);

    if (badgeRes.rows.length === 0) return res.status(404).json({ error: 'badge not found' });
    if (userRes.rows.length === 0) return res.status(404).json({ error: 'user not found' });

    const b = badgeRes.rows[0];

    // ── Verificar se já existe imagem e PDF guardados ──
    const existingData = await pool.query(
      'SELECT badge_image_base64, certificado_pdf_base64 FROM candidaturasbadge WHERE idcandidatura = $1',
      [candCheck.rows[0].idcandidatura]
    );
    const existingRow = existingData.rows[0];
    if (existingRow?.badge_image_base64 && existingRow?.certificado_pdf_base64) {
      return res.json({
        base64: existingRow.badge_image_base64,
        certificado_pdf_base64: existingRow.certificado_pdf_base64
      });
    }

    // Canvas size (LinkedIn recommended social card ~1200x630)
    const width = 1200;
    const height = 630;
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');

    // background
    ctx.fillStyle = '#F9FAFB';
    ctx.fillRect(0, 0, width, height);

    // white card
    ctx.fillStyle = '#FFFFFF';
    const pad = 40;
    ctx.fillRect(pad, pad, width - pad * 2, height - pad * 2);

    // draw badge image (if exists)
    try {
      if (badge.imagemurl) {
        const badgeImg = await loadImage(badge.imagemurl);
        const bsize = 180;
        ctx.drawImage(badgeImg, pad + 20, pad + 40, bsize, bsize);
      }
    } catch (e) {
      console.warn('Failed to load badge image', e.message || e);
    }

    // draw user photo (if exists)
    try {
      if (user.fotourl) {
        let userSrc = user.fotourl;
        // handle base64 stored directly
        if (!userSrc.startsWith('data:') && /^[A-Za-z0-9+/=\s]+$/.test(userSrc) && userSrc.length > 200) {
          userSrc = `data:image/png;base64,${userSrc}`;
        }
        const uimg = await loadImage(userSrc);
        const usz = 120;
        const ux = width - pad - usz - 20;
        const uy = pad + 40;
        // circle clip
        ctx.save();
        ctx.beginPath();
        ctx.arc(ux + usz / 2, uy + usz / 2, usz / 2, 0, Math.PI * 2);
        ctx.closePath();
        ctx.clip();
        ctx.drawImage(uimg, ux, uy, usz, usz);
        ctx.restore();
      }
    } catch (e) {
      console.warn('Failed to load user image', e.message || e);
    }

    // Text: badge name
    ctx.fillStyle = '#0F172A';
    ctx.font = 'bold 48px Sans';
    ctx.fillText(badge.nome || 'Badge', 240, 160);

    // Text: badge description (smaller)
    ctx.fillStyle = '#475569';
    ctx.font = '24px Sans';
    const desc = badge.descricao ? String(badge.descricao).slice(0, 180) : '';
    ctx.fillText(desc, 240, 210);

    // Text: user name
    ctx.fillStyle = '#0F172A';
    ctx.font = '28px Sans';
    ctx.fillText(user.nome || '', 240, 280);

    // Footer / date
    ctx.fillStyle = '#64748B';
    ctx.font = '18px Sans';
    const dateStr = new Date().toLocaleDateString();
    ctx.fillText(`Conquistado em ${dateStr}`, 240, height - 80);

    const buffer = canvas.toBuffer('image/png');

    // ── GERAR PDF DO CERTIFICADO a partir da mesma imagem ──
    let pdfBase64 = null;
    try {
      const userRes = await pool.query(
        'SELECT nome FROM utilizadores WHERE idutilizador = $1',
        [userId]
      );
      const userName = userRes.rows[0]?.nome || 'Utilizador';

      // Carregar imagem do badge antes de criar o PDF (evita async dentro do Promise do PDFKit)
      let badgeImg = null;
      try {
        if (b.imagemurl) {
          badgeImg = await loadImage(b.imagemurl);
        }
      } catch (_) {}

      const doc = new PDFDocument({ size: 'A4', layout: 'landscape', margin: 0 });
      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));

      await new Promise((resolve, reject) => {
        doc.on('end', resolve);
        doc.on('error', reject);

        // Fundo branco
        doc.rect(0, 0, doc.page.width, doc.page.height).fill('#ffffff');

        // Borda decorativa azul escura
        doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40)
           .lineWidth(4).stroke('#1E3A5F');

        // Linha decorativa adicional
        doc.rect(30, 30, doc.page.width - 60, doc.page.height - 60)
           .lineWidth(1).stroke('#38BDF8');

        // Logo SOFTINSA
        doc.font('Helvetica-Bold').fontSize(36).fillColor('#1E3A5F');
        doc.text('S', 60, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('O', 72, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('F', 87, 60, { continued: true });
        doc.fillColor('#38BDF8').text('T', 108, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('I', 123, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('N', 135, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('S', 153, 60, { continued: true });
        doc.fillColor('#1E3A5F').text('A', 171, 60, { continued: true });

        // Título do certificado
        doc.fontSize(28).fillColor('#1E3A5F');
        doc.text('CERTIFICADO DE COMPETÊNCIA', 60, 120, { align: 'center', width: doc.page.width - 120 });

        // Subtítulo
        doc.fontSize(16).fillColor('#555555');
        doc.text('Este certificado é atribuído a:', 60, 175, { align: 'center', width: doc.page.width - 120 });

        // Nome do utilizador
        doc.font('Helvetica-Bold').fontSize(32).fillColor('#1E3A5F');
        doc.text(userName, 60, 210, { align: 'center', width: doc.page.width - 120 });

        // Texto explicativo
        doc.font('Helvetica').fontSize(14).fillColor('#444444');
        doc.text(
          `Pela conclusão com sucesso do badge "${b.nome}" no âmbito do programa Softinsa Talent Management.`,
          80, 270,
          { align: 'center', width: doc.page.width - 160, lineGap: 8 }
        );

        // Detalhes do badge
        const detailsY = 340;
        doc.fontSize(12).fillColor('#666666');
        if (b.area_nome) {
          doc.text(`Área: ${b.area_nome}`, 80, detailsY, { width: doc.page.width - 160 });
        }
        if (b.nivel_nome) {
          doc.text(`Nível: ${b.nivel_nome}`, 80, detailsY + 22, { width: doc.page.width - 160 });
        }
        if (b.pontos) {
          doc.text(`Pontos: ${b.pontos}`, 80, detailsY + 44, { width: doc.page.width - 160 });
        }

        // Imagem do badge no canto inferior direito
        if (badgeImg) {
          doc.image(badgeImg, doc.page.width - 160, doc.page.height - 160, {
            width: 100, height: 100
          });
        }

        // Data de emissão
        const today = new Date();
        const dataStr = today.toLocaleDateString('pt-PT', {
          day: 'numeric', month: 'long', year: 'numeric'
        });
        doc.fontSize(11).fillColor('#888888');
        doc.text(`Emissão: ${dataStr}`, 60, doc.page.height - 80, { width: doc.page.width - 120, align: 'center' });

        // Footer
        doc.fontSize(10).fillColor('#AAAAAA');
        doc.text('Softinsa Talent Management', 60, doc.page.height - 55, { width: doc.page.width - 120, align: 'center' });

        doc.end();
      });

      const pdfBuffer = Buffer.concat(chunks);
      pdfBase64 = pdfBuffer.toString('base64');
    } catch (pdfErr) {
      console.warn('Erro ao gerar PDF do certificado:', pdfErr.message);
    }

    // Guardar imagem e PDF na BD
    try {
      await pool.query('ALTER TABLE candidaturasbadge ADD COLUMN IF NOT EXISTS badge_image_base64 TEXT');
      await pool.query('ALTER TABLE candidaturasbadge ADD COLUMN IF NOT EXISTS certificado_pdf_base64 TEXT');
      await pool.query(
        `UPDATE candidaturasbadge SET badge_image_base64 = $1, certificado_pdf_base64 = COALESCE($2, certificado_pdf_base64) WHERE idcandidatura = $3`,
        [base64str, pdfBase64, candCheck.rows[0].idcandidatura]
      );
    } catch (e) {
      console.warn('Não foi possível guardar na BD:', e.message);
    }

    return res.json({
      base64: base64str,
      certificado_pdf_base64: pdfBase64
    });
  } catch (err) {
    console.error('Erro ao gerar imagem do badge:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────
// DASHBOARD — Learning Path Progress
// GET /utilizadores/:id/dashboard
// ─────────────────────────────────────────────────────────
app.get('/utilizadores/:id/dashboard', async (req, res) => {
  const userId = parseInt(req.params.id, 10);
  if (isNaN(userId)) return res.status(400).json({ error: 'ID inválido' });

  try {
    const lpRes = await pool.query(
      `SELECT nome FROM learningpaths WHERE ativo = TRUE ORDER BY idlearningpath ASC LIMIT 1`
    );
    const learningPathNome = lpRes.rows[0]?.nome ?? 'Jornada Técnica';

    // Contagem global: total de badges ativos e aprovados pelo utilizador
    const countRes = await pool.query(`
      SELECT
        COUNT(b.idbadge)::int                                  AS total,
        COUNT(b.idbadge) FILTER (WHERE cb.estado = 'APPROVED')::int AS aprovados
      FROM badges b
      LEFT JOIN candidaturasbadge cb
             ON cb.badge_id = b.idbadge AND cb.user_id = $1
      WHERE b.ativo = TRUE
    `, [userId]);
    const totalBadges   = countRes.rows[0]?.total    ?? 0;
    const badgesAprovados = countRes.rows[0]?.aprovados ?? 0;

    // CTE em dois passos para evitar o problema DISTINCT + ROW_NUMBER():
    // 1) distinct_niveis: pares (area, nivel) únicos
    // 2) nivel_rank: aplica ROW_NUMBER() sobre esses pares únicos → 1=A, 2=B...
    const { rows } = await pool.query(`
      WITH distinct_niveis AS (
        SELECT DISTINCT a.idarea, n.idnivel
        FROM areas  a
        INNER JOIN badges b ON b.idarea  = a.idarea   AND b.ativo = TRUE
        INNER JOIN nivel  n ON n.idnivel = b.idnivel
        WHERE a.ativo = TRUE
      ),
      nivel_rank AS (
        SELECT
          sl.idserviceline,
          sl.nome                                              AS serviceline_nome,
          a.idarea,
          a.nome                                               AS area_nome,
          dn.idnivel,
          n.nome                                               AS nivel_nome,
          ROW_NUMBER() OVER (
            PARTITION BY a.idarea ORDER BY dn.idnivel ASC
          )                                                    AS pos
        FROM distinct_niveis dn
        INNER JOIN areas       a  ON a.idarea       = dn.idarea
        INNER JOIN serviceline sl ON sl.idserviceline = a.idserviceline AND sl.ativo = TRUE
        INNER JOIN nivel       n  ON n.idnivel       = dn.idnivel
      )
      SELECT
        nr.idserviceline,
        nr.serviceline_nome,
        nr.idarea,
        nr.area_nome,
        CHR(64 + nr.pos::int)                                  AS nivel_grupo,
        nr.nivel_nome,
        COUNT(DISTINCT b.idbadge)::int                         AS total_badges,
        COUNT(DISTINCT b.idbadge) FILTER (
          WHERE cb.estado = 'APPROVED'
        )::int                                                 AS badges_aprovados,
        CASE
          WHEN COUNT(b.idbadge) FILTER (WHERE cb.estado = 'APPROVED') > 0
            THEN 'APPROVED'
          WHEN COUNT(b.idbadge) FILTER (
            WHERE cb.estado IN ('SUBMITTED','UNDER_REVIEW')
          ) > 0 THEN 'SUBMITTED'
          WHEN COUNT(b.idbadge) FILTER (WHERE cb.estado = 'OPEN') > 0
            THEN 'OPEN'
          ELSE 'NAO_INICIADO'
        END                                                    AS estado
      FROM nivel_rank nr
      INNER JOIN badges b ON b.idarea = nr.idarea AND b.idnivel = nr.idnivel AND b.ativo = TRUE
      LEFT  JOIN candidaturasbadge cb
             ON cb.badge_id = b.idbadge AND cb.user_id = $1
      WHERE nr.pos <= 5
      GROUP BY nr.idserviceline, nr.serviceline_nome, nr.idarea, nr.area_nome,
               nr.idnivel, nr.nivel_nome, nr.pos
      ORDER BY nr.idserviceline ASC, nr.idarea ASC, nr.pos ASC
    `, [userId]);

    const slMap = new Map();

    for (const row of rows) {

      if (!slMap.has(row.idserviceline)) {
        slMap.set(row.idserviceline, {
          idserviceline: row.idserviceline,
          nome: row.serviceline_nome,
          areas: new Map()
        });
      }
      const sl = slMap.get(row.idserviceline);

      if (!sl.areas.has(row.idarea)) {
        sl.areas.set(row.idarea, { idarea: row.idarea, nome: row.area_nome, niveis: [] });
      }
      sl.areas.get(row.idarea).niveis.push({
        nivel_grupo:      row.nivel_grupo,      // "A", "B", "C", "D", "E"
        total_badges:     parseInt(row.total_badges),
        badges_aprovados: parseInt(row.badges_aprovados),
        estado:           row.estado,
      });
    }
  } catch (err) {
    console.error('Erro ao gerar imagem do badge:', err.message || err);
    res.status(500).json({ error: err.message || String(err) });
  }
});

// Recuperar imagem do badge armazenada numa candidatura
app.get('/candidaturas/:id/badge-image', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) return res.status(400).json({ error: 'ID de candidatura inválido' });

    const result = await pool.query(
      'SELECT badge_image_base64 FROM candidaturasbadge WHERE idcandidatura = $1 LIMIT 1',
      [id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Candidatura não encontrada' });

    res.json({ base64: result.rows[0].badge_image_base64 });
  } catch (err) {
    console.error('Erro ao recuperar imagem da candidatura:', err.message || err);
    res.status(500).json({ error: err.message || String(err) });
  }
});