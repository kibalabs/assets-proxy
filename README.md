# assets-proxy

CloudFront CDN for Kiba Labs' shared static assets, at `assets-cdn.kiba.dev` and `assets.evrpg.com`.

| Path | Served from |
| --- | --- |
| `/*` | the `kiba-assets-proxy` S3 bucket (icons, badges, ...) |
| `/gfonts/*` | `fonts.googleapis.com` |
| `/gfonts-files/*` | `fonts.gstatic.com` |
| `/calendly-widget.js` | Calendly's embed widget |

Every response allows cross-origin requests.

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
