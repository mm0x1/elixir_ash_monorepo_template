# Pre-Implementation Checklist

**Complete this checklist before writing code for any new feature or significant change.**

---

## 1. Requirements Understanding

- [ ] **User story or requirement is clear** — Can you explain it in one sentence?
- [ ] **Acceptance criteria defined** — How will we know it's done?
- [ ] **Edge cases identified** — What could go wrong?
- [ ] **Scope is bounded** — What's explicitly NOT included?

### Questions to Answer

| Question | Answer |
|----------|--------|
| What problem does this solve? | |
| Who is the user? | |
| What's the happy path? | |
| What are the failure modes? | |

---

## 2. Architecture Decisions

- [ ] **Identified if this needs new Ash resource(s)**
- [ ] **Identified if this needs new action(s) on existing resource**
- [ ] **Decided: Server-side (Inertia) vs client-side (React Query)**
- [ ] **Identified what policies are required**
- [ ] **Identified serialization needs**

### Decision Matrix

| Question | Options | Decision |
|----------|---------|----------|
| Where does data live? | New resource / Existing resource / No persistence | |
| Who can access? | Public / Authenticated / Owner only / Admin only | |
| How is it rendered? | Server-rendered page / Client-fetched data | |

---

## 3. Existing Patterns

- [ ] **Searched for similar features to follow patterns**
- [ ] **Read relevant convention files** (see `conventions/index.md`)
- [ ] **Identified reusable components or functions**
- [ ] **Checked for existing utilities** (formatters, validators, hooks)

### Pattern Sources

| Area | Where to Look |
|------|---------------|
| Ash resources | `lib/template_app/domains/*/resources/` |
| Controllers | `lib/template_app_web/controllers/` |
| Serializers | `lib/template_app_web/serializers/` |
| React pages | `frontend/src/pages/` |
| React components | `frontend/src/components/` |
| Hooks | `frontend/src/lib/hooks/` |

---

## 4. Dependencies & Integration

- [ ] **No circular dependencies introduced**
- [ ] **Actor propagation path is clear** — How does current_user flow through?
- [ ] **Serialization boundary identified** — What goes to frontend?
- [ ] **Error handling strategy decided** — Flash messages? Inline errors? Both?

### Integration Points

| Layer | This feature touches |
|-------|---------------------|
| Database | [ ] New table [ ] Existing table [ ] No DB |
| Ash Resource | [ ] New resource [ ] New action [ ] Existing |
| Controller | [ ] New controller [ ] New action [ ] Existing |
| React Page | [ ] New page [ ] Modify existing |
| React Components | [ ] New components [ ] Existing only |

---

## 5. Testing Strategy

- [ ] **Identified what needs testing**
- [ ] **Decided test scope** — Unit? Integration? E2E?
- [ ] **Identified test data needs**

### Test Outline

| What to Test | Test Type | Notes |
|--------------|-----------|-------|
| | | |
| | | |
| | | |

---

## 6. Ready to Implement?

- [ ] All above sections completed
- [ ] No outstanding questions
- [ ] Conventions files read for relevant areas
- [ ] Can explain the approach in 2-3 sentences

### Implementation Summary

```
Feature: [Name]
Approach: [1-2 sentences]
Files to create/modify: [List]
Estimated complexity: [Simple / Medium / Complex]
```
