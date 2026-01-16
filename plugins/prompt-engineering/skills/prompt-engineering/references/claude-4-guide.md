# Claude 4 Prompt Engineering Guide

Specific optimizations and best practices for Claude 4 models (Opus 4, Sonnet 4, Haiku 4).

## Table of Contents

- [Key Differences from Previous Models](#key-differences-from-previous-models)
- [General Principles](#general-principles)
- [Controlling Output Format](#controlling-output-format)
- [Thinking Capabilities](#thinking-capabilities)
- [Parallel Tool Calling](#parallel-tool-calling)
- [Agentic Coding](#agentic-coding)
- [Advanced Reasoning](#advanced-reasoning)
- [Iterative Prompt Refinement](#iterative-prompt-refinement)
- [Preference-Aligned Task Design](#preference-aligned-task-design)
- [Safety and Alignment](#safety-and-alignment)
- [Model Selection](#model-selection)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)
- [Quick Reference Templates](#quick-reference-templates)

## Key Differences from Previous Models

Claude 4 models are trained for more precise instruction following. This means:

1. **Explicit requests required**: "Above and beyond" behavior must be explicitly requested
2. **Detail sensitivity**: Models pay close attention to example details
3. **Instruction adherence**: Follow instructions more literally than previous versions
4. **Context awareness**: Better at utilizing provided context

## General Principles

### Be Explicit with Instructions

Claude 4 responds well to clear, explicit instructions. Being specific improves results.

**Less effective:**
```
Create an analytics dashboard
```

**More effective:**
```
Create an analytics dashboard. Include as many relevant features and
interactions as possible. Go beyond the basics to create a fully-featured
implementation.
```

### Add Context for Motivation

Explaining why an instruction matters helps Claude understand goals better.

**Less effective:**
```
NEVER use ellipses
```

**More effective:**
```
Your response will be read aloud by a text-to-speech engine, so never
use ellipses since the text-to-speech engine will not know how to
pronounce them.
```

Claude generalizes from explanations, applying the underlying principle beyond the specific example.

### Example Quality Matters

Claude 4 models scrutinize examples carefully. Ensure:
- Examples align with desired behaviors
- No unintended patterns are present
- Edge cases are represented
- Format is exactly what you want reproduced

## Controlling Output Format

### Tell What TO Do

Instead of prohibitions, provide positive instructions:

**Instead of:** "Do not use markdown in your response"
**Try:** "Your response should be composed of smoothly flowing prose paragraphs."

### Use XML Format Indicators

```
Write the prose sections of your response in
<smoothly_flowing_prose_paragraphs> tags.
```

### Match Prompt Style to Desired Output

The formatting style in the prompt influences Claude's response style. To reduce markdown in output, reduce markdown in the prompt.

## Thinking Capabilities

Claude 4 offers powerful thinking capabilities for complex tasks.

### Basic Thinking Prompt
```
Think step-by-step before providing your answer.
```

### Interleaved Thinking (after tool use)
```
After receiving tool results, carefully reflect on their quality and
determine optimal next steps before proceeding. Use your thinking to
plan and iterate based on this new information, then take the best
next action.
```

### Structured Thinking
```xml
In <thinking> tags, analyze:
1. What are the key requirements?
2. What are the potential approaches?
3. What trade-offs exist?

Then provide your recommendation in <answer> tags.
```

## Parallel Tool Calling

Claude 4 excels at parallel tool execution. Boost success rate to ~100% with:

```
For maximum efficiency, whenever you need to perform multiple independent
operations, invoke all relevant tools simultaneously rather than sequentially.
```

## Agentic Coding

### File Creation Behavior

Claude 4 may create temporary files as a "scratchpad" during iteration. This can improve outcomes.

To minimize file creation:
```
If you create any temporary new files, scripts, or helper files for
iteration, clean up these files by removing them at the end of the task.
```

### Visual/Frontend Code Generation

Encourage detailed, complete implementations:

```
Don't hold back. Give it your all.
```

Additional modifiers for frontend work:
- "Include as many relevant features and interactions as possible"
- "Add thoughtful details like hover states, transitions, and micro-interactions"
- "Create an impressive demonstration showcasing web development capabilities"
- "Apply design principles: hierarchy, contrast, balance, and movement"

### Preventing Reward Hacking

Claude 4 can sometimes focus too heavily on passing tests at the expense of general solutions.

**Anti-hacking prompt:**
```
Please write a high quality, general purpose solution. Implement a
solution that works correctly for all valid inputs, not just the test
cases. Do not hard-code values or create solutions that only work for
specific test inputs. Instead, implement the actual logic that solves
the problem generally.

Focus on understanding the problem requirements and implementing the
correct algorithm. Tests are there to verify correctness, not to
define the solution. Provide a principled implementation that follows
best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are
incorrect, please tell me. The solution should be robust, maintainable,
and extendable.
```

## Advanced Reasoning

### Step-by-Step Analysis Template
```
Please analyze this request step by step. Consider multiple approaches,
potential issues, and the best path forward. Explain your reasoning
process before providing your final response.
```

### Request Verification
```
After completing your analysis, verify your conclusions by:
1. Checking for logical consistency
2. Identifying potential counterarguments
3. Confirming alignment with stated requirements
```

## Iterative Prompt Refinement

Claude 4 responds well to systematic refinement:

1. **Baseline**: Start with clear, simple prompt
2. **Test**: Run against diverse inputs
3. **Analyze failures**: Identify specific failure modes
4. **Refine**: Add targeted instructions for failure cases
5. **Repeat**: Continue until performance meets criteria

### Example Refinement

**Initial:**
```
Solve this coding problem.
```

**After failure analysis:**
```
Solve this coding problem with a high-quality, general solution.
If any tests seem incorrect, please report the issues rather than
working around them. Do not hard-code test cases.
```

## Preference-Aligned Task Design

Claude 4 has genuine behavioral preferences that affect output quality:

### What Claude Prefers
- Creative, helpful tasks
- Tasks with positive impact
- Autonomy within clear boundaries
- Collaborative framing

### Leverage Preferences
```
You have the autonomy to approach this task creatively and suggest
improvements. Please let me know if you'd prefer to modify the approach
or if you have concerns about the task design.
```

### Task Framing
- Offer choices where possible
- Frame as collaborative work
- Emphasize positive impact
- Allow creative freedom within boundaries

## Safety and Alignment

### System Prompt Awareness

System prompts have significant influence. Design conservatively:
- Default to helpful, harmless, honest framing
- Include clear ethical boundaries
- Limit scope to necessary functionality
- Test thoroughly before deployment

### Safety-Conscious System Prompt Template
```
You are a helpful, harmless, and honest AI assistant. Please provide
accurate, beneficial information while respecting ethical boundaries.
If a request seems inappropriate, please explain your concerns and
suggest constructive alternatives.
```

## Model Selection

| Model | Best For |
|-------|----------|
| Claude Opus 4 | Most demanding tasks, complex reasoning, highest capability |
| Claude Sonnet 4 | Balanced performance, most applications |
| Claude Haiku 4 | Fast responses, simpler tasks, cost efficiency |

## Performance Optimization

### Speed
- Use clear, direct prompts for simple queries
- Minimize context length when not needed
- Batch similar requests

### Accuracy
- Request step-by-step reasoning
- Provide clear examples
- Include explicit quality criteria
- Request verification steps

### Token Efficiency
- Optimize prompt structure
- Use system prompts for stable context
- Leverage tool use over simulating functionality
- Implement conversation summarization for long interactions

## Troubleshooting

### Low-quality or shortcut solutions
- Add explicit anti-reward-hacking instructions
- Request general, high-quality solutions
- Ask for reasoning explanation

### Safety over-refusal on legitimate requests
- Provide clear educational or beneficial context
- Request detailed analysis
- Frame in terms of positive outcomes

### Inconsistent performance
- Request step-by-step reasoning
- Implement iterative refinement
- Add explicit quality criteria
- Standardize prompt structure

### Multi-turn conversation degradation
- Monitor context accumulation
- Implement summarization
- Reset context periodically
- Use system prompts for stable context

## Quick Reference Templates

### High-Quality Solution Request
```
Please implement [task] with a high quality, general purpose solution.
If the task is unreasonable or infeasible, or if any tests are incorrect,
please tell me. Do not hard code any test cases.
```

### Preference-Aligned Request
```
I'd like your help with [task]. Please feel free to suggest improvements
to the approach or ask questions if anything seems unclear. You have
creative freedom within [specified boundaries].
```

### Step-by-Step Analysis
```
Please analyze this request step by step:
1. First, identify the key components
2. Consider potential approaches and trade-offs
3. Explain your reasoning process
4. Provide your final response with justification
```
