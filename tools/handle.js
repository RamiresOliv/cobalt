const express = require("express");
const { resolve } = require("path");
const { exec } = require("child_process");
const fs = require("fs");

const app = express();

app.listen(1234);
app.use(express.json({ limit: "100gb" }));

function sysrun(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Erro: ${error.message}`);
        reject(error);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
        resolve(stderr);
        return;
      }
      console.log(`Output: ${stdout}`);
      resolve(stdout);
    });
  });
}

sysrun("echo %cd%");

function p(...args) {
  let r = resolve(".");

  for (const i in args) {
    const v = args[i];
    r = resolve(r, v);
  }
  return r;
}

function deleteFolderRecursive(folderPath) {
  if (fs.existsSync(folderPath)) {
    fs.rmSync(folderPath, { recursive: true, force: true });
  }
}

const solveThings = async (path, childs) => {
  for (const childName in childs) {
    const childData = childs[childName];
    if (childData.isA == "folder") {
      fs.mkdirSync(resolve(path, childName));
      await solveThings(resolve(path, childName), childData.content);
    } else {
      fs.appendFileSync(
        resolve(path, childName + "." + childData.isA),
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
app.post("/", async (req, res) => {
  const data = req.body;

  const read = fs.readdirSync(resolve("."));
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
      child == ".gitignore"
    )
      continue;
    console.log("removing: " + child);
    deleteFolderRecursive(p(child));
  }
  console.log("all clear.");
  console.log("working in directories...");

  for (const i in data.map) {
    const ROOTFOLDER = data[i];
    fs.mkdirSync(p(i));
    await solveThings(p(i), ROOTFOLDER);
  }

  setTimeout(async () => {
    await sysrun("git add .");
    console.log(data.game);
    await sysrun(
      `git commit -m "${data.game.versionName} ${data.game.version}"`
    );
    await sysrun("git push cobalt");
  }, 2000);
  return res.send("Thanks.");
});