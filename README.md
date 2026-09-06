# Python Service Foundation

An opinionated Python service foundation for bootstrapping consistent, maintainable services.

It provides a small Copier template and project-governance starting point without prescribing a product domain.

## Render the template

```bash
uvx --from copier==9.18.1 copier copy . /path/to/new-service
```

## Verify update metadata

Run the focused local validation against a Git ref before releasing a template
change. It renders a disposable project and verifies that its
`.copier-answers.yml` contains Copier's source and commit metadata as well as
the project answers required by this template.

```bash
scripts/validate-copier-metadata.sh HEAD
```
