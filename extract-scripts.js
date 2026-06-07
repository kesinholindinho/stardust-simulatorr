#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const ROOT = process.cwd();
const OUTPUT_DIR = path.join(ROOT, "extracted-scripts");
const REPORT_PATH = path.join(ROOT, "EXTRACTION_REPORT.md");

const SCRIPT_EXTENSIONS = {
  Script: ".server.luau",
  LocalScript: ".client.luau",
  ModuleScript: ".luau",
};

const INVALID_WINDOWS_CHARS = /[<>:"/\\|?*\x00-\x1F]/g;
const RESERVED_WINDOWS_NAMES = /^(con|prn|aux|nul|com[1-9]|lpt[1-9])$/i;

function usage() {
  console.log("Uso: node extract-scripts.js <arquivo.rbxlx>");
  console.log("Se nenhum arquivo for informado, o primeiro .rbxlx na pasta atual sera usado.");
}

function findDefaultRbxlx() {
  return fs
    .readdirSync(ROOT, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".rbxlx"))
    .map((entry) => path.join(ROOT, entry.name))
    .sort()[0];
}

function decodeXmlEntities(value) {
  if (!value) return "";
  return value
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#([0-9]+);/g, (_, num) => String.fromCodePoint(parseInt(num, 10)))
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

function sanitizeName(name, fallback = "Unnamed") {
  let clean = decodeXmlEntities(name || fallback)
    .replace(INVALID_WINDOWS_CHARS, "_")
    .replace(/\s+/g, " ")
    .trim();

  clean = clean.replace(/[. ]+$/g, "");
  if (!clean) clean = fallback;
  if (RESERVED_WINDOWS_NAMES.test(clean)) clean = `_${clean}`;
  return clean.slice(0, 120);
}

function extractAttribute(tag, attribute) {
  const re = new RegExp(`${attribute}\\s*=\\s*"([^"]*)"`);
  const match = tag.match(re);
  return match ? decodeXmlEntities(match[1]) : "";
}

function extractName(block) {
  const nameMatch = block.match(/<string\s+name="Name"\s*>([\s\S]*?)<\/string>/i);
  return nameMatch ? decodeXmlEntities(nameMatch[1]) : "";
}

function extractSource(block) {
  const protectedMatch = block.match(/<ProtectedString\s+name="Source"\s*>([\s\S]*?)<\/ProtectedString>/i);
  if (protectedMatch) return decodeXmlEntities(protectedMatch[1]);

  const stringMatch = block.match(/<string\s+name="Source"\s*>([\s\S]*?)<\/string>/i);
  if (stringMatch) return decodeXmlEntities(stringMatch[1]);

  return "";
}

function getTopFolder(pathParts) {
  return pathParts[0] || "Root";
}

function uniqueFilePath(filePath, usedPaths) {
  const parsed = path.parse(filePath);
  let candidate = filePath;
  let index = 2;

  while (usedPaths.has(candidate.toLowerCase()) || fs.existsSync(candidate)) {
    candidate = path.join(parsed.dir, `${parsed.name}_${index}${parsed.ext}`);
    index += 1;
  }

  usedPaths.add(candidate.toLowerCase());
  return candidate;
}

function clearDirectory(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
}

function parseItems(xml) {
  const root = { className: "DataModel", name: "Game", children: [], parent: null };
  const stack = [root];
  let cursor = 0;

  while (cursor < xml.length) {
    const nextOpen = xml.indexOf("<Item", cursor);
    const nextClose = xml.indexOf("</Item>", cursor);

    if (nextOpen === -1 && nextClose === -1) break;

    if (nextOpen !== -1 && (nextClose === -1 || nextOpen < nextClose)) {
      const tagEnd = xml.indexOf(">", nextOpen);
      if (tagEnd === -1) break;

      const tag = xml.slice(nextOpen, tagEnd + 1);
      const className = extractAttribute(tag, "class") || "Unknown";
      const selfClosing = /\/>\s*$/.test(tag);
      const item = { className, name: "", children: [], parent: stack[stack.length - 1], start: tagEnd + 1, end: null };
      stack[stack.length - 1].children.push(item);

      if (!selfClosing) stack.push(item);
      cursor = tagEnd + 1;
    } else {
      const item = stack.pop();
      if (!item || item === root) {
        cursor = nextClose + 7;
        continue;
      }

      item.end = nextClose;
      const block = xml.slice(item.start, item.end);
      item.name = extractName(block) || item.className;
      if (SCRIPT_EXTENSIONS[item.className]) item.source = extractSource(block);
      cursor = nextClose + 7;
    }
  }

  return root;
}

function collectScripts(node, pathParts, scripts) {
  for (const child of node.children) {
    const childName = sanitizeName(child.name || child.className);
    const nextPath = child.className === "DataModel" ? pathParts : pathParts.concat(childName);

    if (SCRIPT_EXTENSIONS[child.className]) {
      scripts.push({
        className: child.className,
        name: childName,
        source: child.source || "",
        hierarchy: nextPath,
      });
    }

    collectScripts(child, nextPath, scripts);
  }
}

function writeScripts(scripts) {
  const usedPaths = new Set();
  const written = [];

  clearDirectory(OUTPUT_DIR);

  for (const script of scripts) {
    const folderParts = script.hierarchy.slice(0, -1).map((part) => sanitizeName(part));
    const baseName = sanitizeName(script.hierarchy[script.hierarchy.length - 1] || script.name);
    const ext = SCRIPT_EXTENSIONS[script.className];
    const folder = path.join(OUTPUT_DIR, ...folderParts);
    fs.mkdirSync(folder, { recursive: true });

    const desired = path.join(folder, `${baseName}${ext}`);
    const filePath = uniqueFilePath(desired, usedPaths);
    fs.writeFileSync(filePath, script.source, "utf8");

    written.push({ ...script, filePath });
  }

  return written;
}

function createReport({ inputFile, scripts, written, warnings, errors }) {
  const counts = { Script: 0, LocalScript: 0, ModuleScript: 0 };
  const emptyScripts = [];
  const topFolders = new Set();

  for (const script of scripts) {
    counts[script.className] += 1;
    topFolders.add(getTopFolder(script.hierarchy));
    if (!script.source || script.source.trim() === "") emptyScripts.push(script.hierarchy.join("/"));
  }

  const lines = [
    "# Relatorio de Extracao",
    "",
    `Arquivo analisado: ${inputFile ? `\`${path.relative(ROOT, inputFile) || inputFile}\`` : "nenhum arquivo .rbxlx encontrado"}`,
    `Scripts extraidos: ${written.length}`,
    "",
    "## Contagem por tipo",
    "",
    `- Script: ${counts.Script}`,
    `- LocalScript: ${counts.LocalScript}`,
    `- ModuleScript: ${counts.ModuleScript}`,
    "",
    "## Pastas principais encontradas",
    "",
    ...(topFolders.size ? [...topFolders].sort().map((folder) => `- ${folder}`) : ["- Nenhuma"]),
    "",
    "## Scripts vazios",
    "",
    ...(emptyScripts.length ? emptyScripts.sort().map((item) => `- ${item}`) : ["- Nenhum"]),
    "",
    "## Avisos",
    "",
    ...(warnings.length ? warnings.map((warning) => `- ${warning}`) : ["- Nenhum"]),
    "",
    "## Erros",
    "",
    ...(errors.length ? errors.map((error) => `- ${error}`) : ["- Nenhum"]),
    "",
    "## Observacoes",
    "",
    "- O extrator preserva a hierarquia encontrada no XML do Roblox sempre que possivel.",
    "- Arquivos com nomes duplicados recebem sufixos como `_2` e `_3`.",
    "- Scripts extraidos ficam em `extracted-scripts`; nada e apagado de `src` por este extrator.",
    "",
  ];

  fs.writeFileSync(REPORT_PATH, lines.join("\n"), "utf8");
}

function main() {
  const warnings = [];
  const errors = [];
  const inputArg = process.argv[2];
  const inputFile = inputArg ? path.resolve(ROOT, inputArg) : findDefaultRbxlx();

  if (!inputFile) {
    errors.push("Nenhum arquivo .rbxlx foi encontrado na raiz do projeto.");
    warnings.push("Coloque o arquivo .rbxlx em C:\\Users\\pedra\\Documents\\Codex\\2026-06-04\\voce-consegue-ter-acesso-ao-roblox e rode `node extract-scripts.js nome-do-arquivo.rbxlx`.");
    clearDirectory(OUTPUT_DIR);
    createReport({ inputFile: null, scripts: [], written: [], warnings, errors });
    usage();
    process.exitCode = 1;
    return;
  }

  if (!inputFile.toLowerCase().endsWith(".rbxlx")) {
    errors.push("O arquivo informado nao termina com .rbxlx.");
  }

  if (!fs.existsSync(inputFile)) {
    errors.push(`Arquivo nao encontrado: ${inputFile}`);
    createReport({ inputFile, scripts: [], written: [], warnings, errors });
    process.exitCode = 1;
    return;
  }

  const xml = fs.readFileSync(inputFile, "utf8");
  const tree = parseItems(xml);
  const scripts = [];
  collectScripts(tree, [], scripts);

  if (scripts.length === 0) {
    warnings.push("Nenhum Script, LocalScript ou ModuleScript foi encontrado no arquivo.");
  }

  const written = writeScripts(scripts);
  createReport({ inputFile, scripts, written, warnings, errors });
  console.log(`Extraidos ${written.length} scripts para ${path.relative(ROOT, OUTPUT_DIR)}.`);
  console.log(`Relatorio criado em ${path.relative(ROOT, REPORT_PATH)}.`);
}

main();
