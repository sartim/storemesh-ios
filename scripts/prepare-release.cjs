const fs = require("node:fs");

const version = process.argv[2];
if (!/^\d+\.\d+\.\d+$/.test(version ?? "")) throw new Error("semantic-release supplied an invalid SemVer");
const [major, minor, patch] = version.split(".").map(Number);
const buildNumber = major * 1_000_000 + minor * 1_000 + patch;
const path = "storemesh-ios.xcodeproj/project.pbxproj";
let source = fs.readFileSync(path, "utf8");
source = source.replace(/MARKETING_VERSION = [^;]+/g, `MARKETING_VERSION = ${version}`);
source = source.replace(/CURRENT_PROJECT_VERSION = [^;]+/g, `CURRENT_PROJECT_VERSION = ${buildNumber}`);
fs.writeFileSync(path, source);
