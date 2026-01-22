Install script testing results

Installed debian to start from scratch.

Install Nvidia driver failed in setup-homelab.scratch
Attempted to follow manual directions, manual directions missing how to generate the authelia secrets
script didn't generate
  AUTHELIA_JWT_SECRET=generate-with-openssl-rand-hex-64
  AUTHELIA_SESSION_SECRET=generate-with-openssl-rand-hex-64
  AUTHELIA_STORAGE_ENCRYPTION_KEY=generate-with-openssl-rand-hex-64

in setup-homelab.sh
commented out the apt install nvidia lines
script completed successfully, but still missing authelia secrets

ran deploy script, it completed successfully as well.
however missing authelia secrets prevents proxy access

Fix setup and deploy scripts to ensure an effortless install from scratch for the user experience.
Confirm they work as intended, and services are available by proxy url.



