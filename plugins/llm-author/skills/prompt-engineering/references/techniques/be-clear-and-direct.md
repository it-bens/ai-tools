# Be Clear and Direct

Claude functions like a brilliant new employee with no prior context on norms, styles, or preferences. The more precisely instructions explain desired outcomes, the better the response.

### The Golden Rule
Show the prompt to a colleague with minimal context. If they're confused, Claude will be too.

### Providing Context

Include contextual information:
- **Purpose**: What task results will be used for
- **Audience**: Who the output is meant for
- **Workflow position**: Where this task fits in a larger process
- **Success definition**: What successful completion looks like

### Specificity Techniques

**Be explicit about output:**
```
Output only the JSON object. Do not include any explanation or preamble.
```

**Use sequential steps:**
```
Instructions:
1. Parse the input data
2. Validate all required fields
3. Transform to the target format
4. Return the result in JSON
```

**Specify format precisely:**
```
Format your response as a markdown table with columns:
| Feature | Description | Priority |
```

### Example: Anonymizing Data

**Vague (produces errors):**
```
Remove all personally identifiable information from these messages.
```

**Clear (produces correct output):**
```
Your task is to anonymize customer feedback for our quarterly review.

Instructions:
1. Replace all customer names with "CUSTOMER_[ID]"
2. Replace email addresses with "EMAIL_[ID]@example.com"
3. Redact phone numbers as "PHONE_[ID]"
4. If a message mentions a specific product, leave it intact
5. If no PII is found, copy the message verbatim
6. Output only the processed messages, separated by "---"

Data to process:
{{FEEDBACK_DATA}}
```
