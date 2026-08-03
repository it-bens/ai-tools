# Prompt Chaining

Break complex tasks into sequential subtasks, each receiving Claude's full attention.

### When to Chain
- Multi-step workflows where output feeds into next step
- Tasks requiring different "modes" (research, then write, then edit)
- Complex processes needing validation between steps

### Chain Structure

**Step 1: Research**
```
Research the topic and provide key findings in <findings> tags.
```

**Step 2: Draft** (receives Step 1 output)
```
Using these findings:
<findings>{{STEP1_OUTPUT}}</findings>

Draft a comprehensive report in <draft> tags.
```

**Step 3: Review** (receives Step 2 output)
```
Review this draft for accuracy and clarity:
<draft>{{STEP2_OUTPUT}}</draft>

Provide specific improvement suggestions.
```

### Best Practices
- Clear handoff format between steps
- Validation at each step before proceeding
- Error handling for failed steps
- Consider parallel chains for independent subtasks
