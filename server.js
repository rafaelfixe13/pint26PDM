const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

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

  await client.query(
    `
    INSERT INTO utilizador_badge
      (user_id, badge_id, progresso_atual, progresso_total, conquistado, data_conquista, created_at, updated_at)
    VALUES
      ($1, $2, $3, $4, FALSE, NULL, NOW(), NOW())
    ON CONFLICT (user_id, badge_id)
    DO UPDATE SET
      progresso_atual = EXCLUDED.progresso_atual,
      progresso_total = EXCLUDED.progresso_total,
      updated_at = NOW()
    `,
    [userId, badgeId, progressoAtual, progressoTotal]
  );

  return {
    progressoAtual,
    progressoTotal,
    submetido,
    estadoVisual,
  };
}

// ─────────────────────────────────────────────────────────
// BADGES
// ─────────────────────────────────────────────────────────
app.get("/badges", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM badges ORDER BY idbadge ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao buscar badges:", err.message);
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
        b.nivel,
        b.pontos,
        b.linkpublicobase,
        b.competencias
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
        COALESCE(ub.progresso_atual, 0) as progresso_atual,
        COALESCE(ub.progresso_total, requisitos_count.total) as progresso_total,
        COALESCE(ub.conquistado, FALSE) as conquistado,
        COALESCE(ub.data_conquista, NULL) as data_conquista,
        COALESCE(ub.created_at, NOW()) as created_at,
        COALESCE(ub.updated_at, NOW()) as updated_at,
        CASE
          WHEN COALESCE(ub.progresso_atual, 0) >= COALESCE(ub.progresso_total, requisitos_count.total) 
          AND requisitos_count.total > 0
            THEN 'Submetido'
          ELSE CONCAT(COALESCE(ub.progresso_atual, 0), '/', COALESCE(ub.progresso_total, requisitos_count.total))
        END AS estado_visual
      FROM badges b
      LEFT JOIN utilizador_badge ub ON ub.user_id = $1 AND ub.badge_id = b.idbadge
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

app.get("/utilizadores/ranking", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT idutilizador, nome, email, fotourl, pontos
      FROM utilizadores
      ORDER BY pontos DESC, nome ASC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error("Erro ao carregar ranking:", err.message);
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
      "SELECT * FROM utilizadores WHERE email = $1",
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
  const { nome, email, password } = req.body;

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
        (nome, email, passwordhash, idrole, emailconfirmado, primeirologin, estadoconta, datacriacao, pontos)
       VALUES ($1, $2, $3, 1, FALSE, TRUE, 'ATIVA', NOW(), 0)
       RETURNING idutilizador, nome, email, fotourl, pontos, datacriacao`,
      [nome, email, hash]
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
app.listen(3000, "0.0.0.0", () => {
  console.log("Servidor a correr em http://0.0.0.0:3000");
});