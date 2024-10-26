const express = require("express");
const path = require("path");
const { exec } = require("child_process");
const fs = require("fs");
const app = express();

const ownerName = "RamiresOliv";
const repoName = "cobalt";
const port = 1234;

app.listen(port);
app.use(express.json({ limit: "100gb" }));

function sysrun(command) {
  fs.appendFileSync(path.resolve(".", "output.log"), `running: ${command}\n`);
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Erro: ${error.message}`);
        fs.appendFileSync(path.resolve(".", "output.log"), error.message);
        resolve(error);
        return;
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
        fs.appendFileSync(path.resolve(".", "output.log"), stderr);
        resolve(stderr);
        return;
      }
      console.log(`sysrun: ${stdout}`);
      fs.appendFileSync(path.resolve(".", "output.log"), stdout);

      resolve(stdout);
    });
  });
}

if (fs.existsSync(path.resolve(".", "output.log"))) {
  fs.writeFileSync(path.resolve(".", "output.log"), "");
} else {
  fs.appendFileSync(path.resolve(".", "output.log"), "");
}

sysrun("echo %cd%");
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
  console.log(childs);
  for (const childName in childs) {
    const childData = childs[childName];
    if (childData.isA == "folder") {
      console.log(path.resolve(strPath, childName));
      fs.mkdirSync(path.resolve(strPath, childName));
      await solveThings(path.resolve(strPath, childName), childData.content);
    } else {
      fs.appendFileSync(
        path.resolve(strPath, childName + "." + childData.isA),
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
      child == "output.log"
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
    await sysrun(
      `git commit -m "${data.game.versionName} ${data.game.version}"`
    );
    await sysrun(
      `git remote add ${repoName} https://github.com/${ownerName}/${repoName}`
    );
    await sysrun(`git push ${repoName} --force`);
    return res.send({
      success: true,
      message: "done.",
    });
  }, 4000);
});
