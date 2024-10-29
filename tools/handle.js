const express = require("express");
const path = require("path");
const { exec } = require("child_process");
const fs = require("fs");
const app = express();

const ownerName = "RamiresOliv";
const repoName = "cobalt";
const port = 1234;
let activeProcess = null; // Variável global para armazenar o processo ativo

app.listen(port);
app.use(express.json({ limit: "100gb" }));

const runsData = {};
function sysrun(id, command) {
  fs.appendFileSync(path.resolve(".", "publish.log"), `running: ${command}\n`);
  return new Promise((resolve, reject) => {
    runsData[id] = exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Erro: ${error.message}`);
        fs.appendFileSync(path.resolve(".", "publish.log"), error.message);
        resolve(error);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
        fs.appendFileSync(path.resolve(".", "publish.log"), stderr);
        resolve(stderr);
        return;
      }
      console.log(`sysrun: ${stdout}`);
      fs.appendFileSync(path.resolve(".", "publish.log"), stdout);

      resolve(stdout);
    });
  });
}

function syskill(id) {
  if (!runsData[id]) return false;
  console.log(runsData[id].pid);
  const command =
    process.platform === "win32"
      ? `taskkill /F /PID ${runsData[id].pid}`
      : `kill -9 ${runsData[id].pid}`;

  fs.appendFileSync(path.resolve(".", "publish.log"), `stopping: ${command}\n`);

  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Erro: ${error.message}`);
        fs.appendFileSync(
          path.resolve(".", "publish.log"),
          `Erro: ${error.message}\n`
        );
        resolve(error);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
        fs.appendFileSync(
          path.resolve(".", "publish.log"),
          `Stderr: ${stderr}\n`
        );
        resolve(stderr);
        return;
      }
      console.log(`syskill: ${stdout}`);
      fs.appendFileSync(
        path.resolve(".", "publish.log"),
        `Processo finalizado: ${stdout}\n`
      );

      resolve(stdout);
    });
  });
}

if (fs.existsSync(path.resolve(".", "publish.log"))) {
  fs.writeFileSync(path.resolve(".", "publish.log"), "");
} else {
  fs.appendFileSync(path.resolve(".", "publish.log"), "");
}

sysrun("ECHOTEST", "echo %cd%");
console.log(`working in: http://localhost:${port.toString()}`);

function p(...args) {
  let r = path.resolve(".");

  for (const i in args) {
    const v = args[i];
    r = path.resolve(r, v);
  }
  return r;
}

function deleteFolderRecursive(folderPath) {
  if (fs.existsSync(folderPath)) {
    fs.rmSync(folderPath, { recursive: true, force: true });
  }
}

const solveThings = async (strPath, childs) => {
  for (const childName in childs) {
    const childData = childs[childName];
    if (childData.isA == "folder") {
      fs.mkdirSync(path.resolve(strPath, childName));
      await solveThings(path.resolve(strPath, childName), childData.content);
    } else {
      var go = "";
      if (childData.isA) {
        go = "." + childData.isA;
      }
      fs.appendFileSync(
        path.resolve(strPath, childName + go),
        childData.content
      );
    }
  }
};

app.get("/", (req, res) => {
  return res.send({
    success: true,
    message: "Hello, send me the things fella.",
  });
});
app.post("/update", async (req, res) => {
  const data = req.body;

  const read = fs.readdirSync(path.resolve("."));
  console.log("cleaning");
  for (const i in read) {
    const child = read[i];
    if (
      child == ".git" ||
      child == "tools" ||
      child == "license.md" ||
      child == "readme.md" ||
      child == "node_modules" ||
      child == "package.json" ||
      child == "package-lock.json" ||
      child == ".gitignore" ||
      child == "publish.log"
    )
      continue;
    console.log("removing: " + child);
    deleteFolderRecursive(p(child));
  }
  console.log("all clear.");
  console.log("making directories");

  for (const i in data.map) {
    const ROOTFOLDER = data.map[i];
    fs.mkdirSync(p(i));
    await solveThings(p(i), ROOTFOLDER);
  }
  console.log("directories ready");
  console.log("update done");
  return res.send({
    success: true,
    message: "done.",
  });
});

app.post("/publish", async (req, res) => {
  const data = req.body;

  console.log("running git");
  setTimeout(async () => {
    await sysrun("GITADD", "git add .");
    await sysrun(
      "GITCOMMIT",
      `git commit -m "${data.game.versionName} ${data.game.version}"`
    );
    await sysrun(
      "GITREMOTEADD",
      `git remote add ${repoName} https://github.com/${ownerName}/${repoName}`
    );
    await sysrun("GITPUSH", `git push ${repoName} --force`);
    console.log("publish done.");
    return res.send({
      success: true,
      message: "done.",
    });
  }, 4000);
});

app.post("/gource", async (req, res) => {
  const data = req.body;

  var all = "";
  for (const i in data) {
    all = " " + all + "--" + i + " " + data[i] + " ";
  }

  console.log("running gource");
  console.log(all);
  sysrun("GOURCERUN", "gource" + all);
  return res.send({
    success: true,
    message: "done.",
  });
});

app.post("/gource/disable", async (req, res) => {
  const data = req.body;

  console.log("stopping gource");
  sysrun("TASKKILLGOURCE", "taskkill /F /IM gource.exe");
  return res.send({
    success: true,
    message: "done.",
  });
});
