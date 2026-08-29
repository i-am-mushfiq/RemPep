# Repository privacy policy

This repository must remain safe to publish publicly.

- Do not commit real contact names, conversation memories, phone numbers, email addresses, birthdays, or exported app data.
- Use neutral fixtures such as `Contact A` in previews and tests.
- Do not commit personal filesystem paths, author biographies, account-profile links, or a populated Apple development-team identifier.
- Never commit certificates, private keys, provisioning profiles, environment files, or Base64 signing material.
- Keep Apple signing assets in the protected `ios-signing` GitHub Environment described in `GITHUB_IPA.md`.
- Before publishing, run `python .github/scripts/check_repository_privacy.py`.

The GitHub Actions verification job runs the same privacy check before compiling or signing the application.
