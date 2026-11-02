// Uploads the icon sets KibaIcon (@kibalabs/ui-react) falls back to into the assets bucket.
// Usage: node scripts/upload-icon-sets.mjs [--dry-run]   (uses the "kiba" aws profile, or AWS_PROFILE)
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const BUCKET = 'kiba-assets-proxy';
const DISTRIBUTION_ID = 'E3FK7ISS64AH0L';
const PROFILE = process.env.AWS_PROFILE || 'kiba';
const isDryRun = process.argv.includes('--dry-run');

// NOTE(krishan711): file names match what follows the prefix in a KibaIcon id (e.g. mui-arrow-back-outlined -> material-icons/v2/arrow-back-outlined.svg)
// Sets whose major version didn't change are updated in place (and invalidated in the cdn), the others get a new folder so old apps keep their icons.
const MATERIAL_STYLES = ['outlined', 'round', 'sharp', 'two-tone'];
const ICON_SETS = [{
  packageName: 'ionicons',
  version: '8.1.0',
  destination: 'ionicons/v8',
  getFiles: (packageDirectory) => listSvgs(path.join(packageDirectory, 'dist/svg')).map((filePath) => [filePath, path.basename(filePath)]),
}, {
  packageName: 'bootstrap-icons',
  version: '1.13.2',
  destination: 'bootstrap-icons/v1',
  isInPlace: true,
  getFiles: (packageDirectory) => listSvgs(path.join(packageDirectory, 'icons')).map((filePath) => [filePath, path.basename(filePath)]),
}, {
  packageName: 'feather-icons',
  version: '4.29.2',
  destination: 'feather/v4',
  isInPlace: true,
  getFiles: (packageDirectory) => listSvgs(path.join(packageDirectory, 'dist/icons')).map((filePath) => [filePath, path.basename(filePath)]),
}, {
  packageName: 'remixicon',
  version: '4.9.1',
  destination: 'remix-icons/v4',
  getFiles: (packageDirectory) => fs.readdirSync(path.join(packageDirectory, 'icons')).flatMap((category) => listSvgs(path.join(packageDirectory, 'icons', category))).map((filePath) => [filePath, path.basename(filePath)]),
}, {
  packageName: '@material-design-icons/svg',
  version: '0.14.15',
  destination: 'material-icons/v2',
  getFiles: (packageDirectory) => ['filled', ...MATERIAL_STYLES].flatMap((style) => listSvgs(path.join(packageDirectory, style)).map((filePath) => {
    const name = path.basename(filePath, '.svg').replace(/_/g, '-');
    return [filePath, style === 'filled' ? `${name}.svg` : `${name}-${style}.svg`];
  })),
}];

const listSvgs = (directory) => fs.readdirSync(directory).filter((fileName) => fileName.endsWith('.svg')).map((fileName) => path.join(directory, fileName));

const run = (command, args, options = {}) => execFileSync(command, args, { stdio: 'inherit', ...options });

const workDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'icon-sets-'));
try {
  const stagingDirectory = path.join(workDirectory, 'staging');
  ICON_SETS.forEach((iconSet) => {
    // NOTE(krishan711): npm pack only downloads the package itself (no dependencies, no install scripts)
    const packDirectory = path.join(workDirectory, iconSet.packageName.replace('/', '-'));
    fs.mkdirSync(packDirectory, { recursive: true });
    const tarballName = execFileSync('npm', ['pack', `${iconSet.packageName}@${iconSet.version}`, '--silent'], { cwd: packDirectory, encoding: 'utf-8' }).trim().split('\n').pop();
    run('tar', ['-xzf', tarballName], { cwd: packDirectory });
    const files = iconSet.getFiles(path.join(packDirectory, 'package'));
    const destinationDirectory = path.join(stagingDirectory, iconSet.destination);
    fs.mkdirSync(destinationDirectory, { recursive: true });
    files.forEach(([filePath, fileName]) => fs.copyFileSync(filePath, path.join(destinationDirectory, fileName)));
    console.log(`${iconSet.packageName}@${iconSet.version}: ${files.length} icons -> ${iconSet.destination}`);
  });
  if (isDryRun) {
    console.log(`Dry run, not uploading. Staged files: ${stagingDirectory}`);
    process.exit(0);
  }
  run('aws', ['s3', 'cp', stagingDirectory, `s3://${BUCKET}/`, '--recursive', '--only-show-errors', '--profile', PROFILE, '--content-type', 'image/svg+xml', '--cache-control', 'public,max-age=31536000']);
  const invalidationPaths = ICON_SETS.filter((iconSet) => iconSet.isInPlace).map((iconSet) => `/${iconSet.destination}/*`);
  run('aws', ['cloudfront', 'create-invalidation', '--profile', PROFILE, '--distribution-id', DISTRIBUTION_ID, '--paths', ...invalidationPaths, '--output', 'text', '--query', 'Invalidation.Id']);
  console.log('Done');
} finally {
  if (!isDryRun) {
    fs.rmSync(workDirectory, { recursive: true, force: true });
  }
}
