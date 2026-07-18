# Architecture

Design artifacts for the repository: diagrams and Architecture Decision Records (ADRs).

## Structure

| Path | Purpose |
| ---- | ------- |
| [`diagrams/`](diagrams/) | Architecture and flow diagrams (source + exported images). |
| [`decision-records/`](decision-records/) | ADRs capturing significant design decisions. |

## Working With ADRs

- Copy [`decision-records/TEMPLATE.md`](decision-records/TEMPLATE.md) to a new,
  numbered file: `NNNN-short-title.md`.
- Number sequentially, starting at `0001`.
- Never rewrite history: supersede an old ADR with a new one and link between them.

## Diagram Conventions

- Keep editable source (e.g. `.drawio`, `.excalidraw`) alongside exported images.
- Export shareable images to [`../assets/diagrams/`](../assets/diagrams/) when embedding.
