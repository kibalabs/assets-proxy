# assets-proxy

CloudFront CDN for Kiba Labs' shared static assets, at `assets-cdn.kiba.dev` and `assets.evrpg.com`.

| Path | Served from |
| --- | --- |
| `/*` | the `kiba-assets-proxy` S3 bucket (icons, badges, ...) |
| `/gfonts/*` | `fonts.googleapis.com` |
| `/gfonts-files/*` | `fonts.gstatic.com` |
| `/calendly-widget.js` | Calendly's embed widget |

Every response allows cross-origin requests.

## Icon sets

`KibaIcon` (`@kibalabs/ui-react`) fetches icons it hasn't bundled from `ionicons/v8`, `bootstrap-icons/v1`, `feather/v4`, `remix-icons/v4` and `material-icons/v2`. To update them, bump the versions in `scripts/upload-icon-sets.mjs` and run it (`--dry-run` to only stage the files):

```bash
node scripts/upload-icon-sets.mjs
```

Older folders (`ionicons/v5`, `remix-icons/v2`, `material-icons/v1`) stay for apps on older ui-react versions.

## Uploading assets

```bash
aws s3 --profile kiba cp <file> s3://kiba-assets-proxy/<path> --content-type <type>
```

## Deploying

The infra is in `infra/` (Terraform), applied by hand:

```bash
cd infra
terraform init
terraform apply
```
