# Python Plan Optimizer

Analyze Python code examples in planning documents for quality, design principles, and improvement opportunities.

## Overview

This plugin provides **read-only analysis** of Python code blocks within planning documents (PLAN.md, design.md, architecture.md). It identifies improvement opportunities using established design principles and modern Python idioms, presenting findings as suggestions for consideration.

**Key Features:**
- **Project Type Awareness** - Tailors analysis depth for POC, MVP, Private, Enterprise, or Open Source projects
- **Design Principle Analysis** - Detects SOLID, DRY, KISS, YAGNI violations
- **Code Smell Detection** - Identifies bloaters, OO abusers, couplers, and more
- **Modern Python Suggestions** - Recommends type hints, dataclasses, pattern matching
- **Respects Architectural Decisions** - Honors explicit choices stated in the document
- **Read-Only Operation** - Generates reports without modifying any files

## Quick Start

### Installation

```bash
/plugin install python-plan-optimizer@itb-ai-tools
```

### Basic Usage

Analyze Python code in planning documents using natural language:

```
Review the Python code in my PLAN.md
Check if the code in design.md follows SOLID principles
Are there any code smells in my architecture doc?
What Python improvements could be made in my design doc?
```

The `python-plan-optimizer` agent will be automatically invoked.

### Batch Analysis

Analyze multiple files at once by specifying a directory or file list:

```
Analyze all the Python code in my ./plan/ directory
Review PLAN.md, design.md, and architecture.md
Check all markdown files in ./docs/ for code smells
```

**Batch mode features:**
- Discovers all `.md` files in a directory
- Filters to only files containing Python code blocks
- Generates per-document analysis plus aggregate summary
- Identifies cross-document patterns and inconsistencies
- Reports skipped/failed documents with reasons

## Project Type Awareness

The plugin adjusts analysis depth based on project type. You can specify the type explicitly or let the plugin detect it from your documents.

### Specifying Project Type

```
Analyze my enterprise project's PLAN.md
Quick review of this POC code in design.md
Review my open source library's architecture.md
```

### Project Types

| Type | Analysis Mode | Use When |
|------|---------------|----------|
| **POC** | Critical issues only | Validating an idea; code is throw-away |
| **MVP** | Critical + High issues | Shipping quickly but building foundation |
| **Private** | All issues (educational) | Learning, experimentation, personal utility |
| **Enterprise** | All issues + verification | Production system, team collaboration |
| **Open Source** | All issues + API focus | Public library consumed by unknown developers |

### What Changes Per Type

| Aspect | POC | MVP | Private | Enterprise | Open Source |
|--------|-----|-----|---------|------------|-------------|
| Severities | Critical | Critical, High | All | All | All |
| Code Smells | Skip | Bloaters only | All | All + consistency | All + API design |
| Type Hints | Skip | Public API | Suggest | Enforce | **Required** |
| Docs | Skip | Public API | Suggest | Required | **Required** |
| Web Verify | Skip | Critical | Optional | **Required** | Required |

**Default:** If no type is specified or detected, `private` mode is used (matches v1.x behavior).

## Workflow

The plugin follows a 6-phase analysis workflow:

### Phase 0: Project Type Context
- Determine project type from prompt, document, or user
- Load appropriate analysis thresholds
- Configure severity filters and verification requirements

### Phase 1: Discovery
- Identify all Python code blocks in the document
- Catalog the purpose of each code example
- Note dependencies between code blocks
- **Identify explicit architectural decisions**

### Phase 2: Assessment
- Evaluate code against design principles (SOLID, DRY, KISS, YAGNI)
- Detect code smells (bloaters, OO abusers, couplers, etc.)
- Identify missing modern Python features

### Phase 3: Planning
- Prioritize findings by impact (Critical > High > Medium > Low)
- Filter suggestions that conflict with explicit decisions
- Organize recommendations by code block

### Phase 4: Recommendations
- Present improvement suggestions with alternatives
- Show before/after code examples (NOT applied)
- Explain benefits and tradeoffs
- **Clarify these are opportunities, not requirements**

### Phase 5: Report
- Generate comprehensive analysis report
- Document architectural decisions respected
- Present actionable recommendations

## Output Format

Each analysis produces:

1. **Analysis Report** - Summary of findings and recommendations
2. **Architectural Context** - Explicit decisions recognized
3. **Code Assessment** - Principle violations and code smells detected
4. **Suggested Improvements** - Code examples showing alternatives (not applied)
5. **Recommendation Rationale** - Why each suggestion could help

**Note:** No files are modified. All suggestions are for consideration only.

## Design Principles Checked

| Principle | Description |
|-----------|-------------|
| SRP | Single Responsibility - one reason to change |
| OCP | Open/Closed - open for extension, closed for modification |
| LSP | Liskov Substitution - subclasses substitutable for base |
| ISP | Interface Segregation - specific interfaces over general |
| DIP | Dependency Inversion - depend on abstractions |
| DRY | Don't Repeat Yourself - single source of truth |
| KISS | Keep It Simple - straightforward over clever |
| YAGNI | You Aren't Gonna Need It - implement only what's required |

## Code Smells Detected

| Category | Examples |
|----------|----------|
| Bloaters | Long methods, large classes, long parameter lists |
| OO Abusers | Switch statements, refused bequest, parallel inheritance |
| Change Preventers | Divergent change, shotgun surgery |
| Dispensables | Dead code, duplicate code, speculative generality |
| Couplers | Feature envy, inappropriate intimacy, message chains |

## Modern Python Features Applied

- Type hints (Python 3.10+ syntax: `str | None`)
- Dataclasses with `@dataclass`, `frozen=True`, `slots=True`
- Pattern matching (`match/case`)
- F-strings and walrus operator
- Pathlib for file operations
- Protocol for structural subtyping

## Contents

```
python-plan-optimizer/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/
│   └── python-plan-optimizer.md # Two-phase orchestrator agent
├── skills/
│   ├── project-type-determination/
│   │   └── SKILL.md             # Project type detection
│   └── python-plan-optimization/
│       ├── SKILL.md             # Core optimization logic
│       └── references/
│           ├── project-type-profiles.md
│           ├── design-principles.md
│           ├── modern-python.md
│           ├── code-smells.md
│           └── behavioral-compatibility.md
├── README.md
└── CLAUDE.md
```

## Reference Documentation

Detailed guidance available in:
- `skills/python-plan-optimization/references/project-type-profiles.md` - Analysis thresholds per project type
- `skills/python-plan-optimization/references/design-principles.md` - SOLID, DRY, KISS, YAGNI with examples
- `skills/python-plan-optimization/references/modern-python.md` - Type hints, dataclasses, idioms
- `skills/python-plan-optimization/references/code-smells.md` - Detection patterns and fixes
- `skills/python-plan-optimization/references/behavioral-compatibility.md` - 13-point verification

## License

MIT
