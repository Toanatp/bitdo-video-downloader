import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const tauriConfigPath = path.join(root, "src-tauri", "tauri.conf.json");
const tauriConfig = JSON.parse(fs.readFileSync(tauriConfigPath, "utf8"));
const version = process.env.APP_VERSION || tauriConfig.version;
const tag = process.env.RELEASE_TAG || `v${version}`;
const repo = process.env.GITHUB_REPOSITORY || "Toanatp/bitdo-video-downloader";
const notes = process.env.UPDATE_NOTES || `Bitdo Downloader ${version}`;
const pubDate = process.env.UPDATE_PUB_DATE || new Date().toISOString();

const bundleRoot = path.join(root, "src-tauri", "target", "release", "bundle");
const nsisDir = path.join(bundleRoot, "nsis");
const msiDir = path.join(bundleRoot, "msi");

function findNewest(dir, predicate) {
  if (!fs.existsSync(dir)) return undefined;
  return fs.readdirSync(dir)
    .map((name) => path.join(dir, name))
    .filter((file) => fs.statSync(file).isFile() && predicate(path.basename(file)))
    .map((file) => ({ file, mtime: fs.statSync(file).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime)[0]?.file;
}

const installer = process.env.UPDATE_INSTALLER_PATH
  ? path.resolve(process.env.UPDATE_INSTALLER_PATH)
  : findNewest(nsisDir, (name) => name.endsWith("_x64-setup.exe") && name.includes(version))
    || findNewest(msiDir, (name) => name.endsWith("_x64_en-US.msi") && name.includes(version));

if (!installer) {
  throw new Error(`Cannot find a Windows updater installer for version ${version} under ${bundleRoot}`);
}

const sigPath = process.env.UPDATE_SIGNATURE_PATH
  ? path.resolve(process.env.UPDATE_SIGNATURE_PATH)
  : `${installer}.sig`;

if (!fs.existsSync(sigPath)) {
  throw new Error(`Missing updater signature: ${sigPath}`);
}

const assetName = process.env.UPDATE_ASSET_NAME || path.basename(installer);
const signature = fs.readFileSync(sigPath, "utf8").trim();
const urlAsset = assetName.split("/").map(encodeURIComponent).join("/");
const latest = {
  version,
  notes,
  pub_date: pubDate,
  platforms: {
    "windows-x86_64": {
      signature,
      url: `https://github.com/${repo}/releases/download/${encodeURIComponent(tag)}/${urlAsset}`,
    },
  },
};

const outDir = path.join(root, "dist-updater");
fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, "latest.json");
fs.writeFileSync(outFile, `${JSON.stringify(latest, null, 2)}\n`);
console.log(outFile);
console.log(JSON.stringify(latest, null, 2));
