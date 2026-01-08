# Contributing to Documentation

This document explains how to contribute to `logd`'s documentation.

## Documentation Structure

The `/docs` directory contains technical documentation organized by module:

```
docs/
├── README.md           # Documentation index
├── logger/             # Logger module docs
│   ├── philosophy.md
│   ├── architecture.md
│   └── roadmap.md
├── handler/            # Handler module docs
├── time/               # Time module docs
└── stack_trace/        # Stack trace module docs
```

## Documentation Standards

### Philosophy Documents
**Purpose**: Explain design principles and rationale.

**Guidelines**:
- Be concise but detailed
- Focus on technical decisions, not marketing
- Include trade-offs and limitations
- Use tables for structured comparisons

### Architecture Documents
**Purpose**: Describe implementation details.

**Guidelines**:
- Include Mermaid diagrams for data flow
- Explain algorithms with complexity analysis
- Document data structures and interfaces
- Reference specific files and line numbers where relevant

### Roadmap Documents
**Purpose**: Track future work and known issues.

**Guidelines**:
- Use priority labels (P0-P3)
- Include actionable checkboxes
- Provide technical context for each item
- Make items machine-parseable for AI agents

## Contributing Changes

### When to Update Documentation

Update docs when:
- Adding new features or modules
- Changing existing behavior
- Identifying design flaws or improvements
- Implementing items from roadmaps

### Documentation PR Guidelines

1. **Update relevant files**: If changing logger behavior, update `docs/logger/architecture.md`
2. **Mark roadmap items**: Check off completed items in roadmap files
3. **Add diagrams**: Use Mermaid for new flows or structures
4. **Link from code**: Reference doc sections in complex code comments

### Mermaid Diagram Standards

```markdown
\`\`\`mermaid
graph LR
    A[Input] --> B[Process]
    B --> C[Output]
\`\`\`
```

- Use descriptive node labels
- Quote labels with special characters: `id["Label (note)"]`
- Prefer `graph LR` for left-to-right flows
- Use `flowchart TD` for top-down processes

## Keeping Documentation Fresh

### Review Process
- Quarterly audit of docs for accuracy
- Update "Last reviewed" dates in doc headers (optional)
- Accept community PRs for doc improvements

### Broken Link Detection
```bash
# Check for broken internal links
grep -r "file:///" docs/ | grep -v "\.md"
```

## Adding New Modules

When adding a new module, create the documentation triad:

```bash
mkdir -p docs/new_module
touch docs/new_module/philosophy.md
touch docs/new_module/architecture.md
touch docs/new_module/roadmap.md
```

Then update `docs/README.md` to link to the new module.

## Questions or Suggestions?

- Open an issue for discussion
- Propose changes via PR
- Tag documentation PRs with `documentation` label
