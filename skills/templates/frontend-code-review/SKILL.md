---
name: frontend-code-review
enabled: true
description: |
  Frontend-focused code review template covering accessibility compliance, rendering performance, bundle size impact, responsive design, UX consistency, and cross-browser compatibility. Provides a comprehensive review framework for React, Vue, Angular, and other frontend framework changes.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/web-app"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: framework
    label: "Frontend Framework"
    required: false
    placeholder: "e.g., React, Vue, Angular, Svelte"
features:
  - CODE_REVIEW
---

# Frontend Code Review Skill

Review frontend PR **#{{ pr_number }}** in **{{ repository }}** ({{ framework }}).

## Workflow

### Phase 1 — Accessibility

```
ACCESSIBILITY (a11y) CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Semantic HTML:
    [ ] Proper heading hierarchy (h1 > h2 > h3)
    [ ] Landmark elements used (nav, main, aside)
    [ ] Lists use ul/ol, not styled divs
[ ] Interactive elements:
    [ ] Buttons use <button>, links use <a>
    [ ] Form inputs have associated labels
    [ ] ARIA attributes used correctly
    [ ] Focus management for modals/dialogs
    [ ] Keyboard navigation works (Tab, Enter, Escape)
[ ] Visual:
    [ ] Color contrast meets WCAG AA (4.5:1 text, 3:1 large)
    [ ] Color is not the sole information conveyor
    [ ] Focus indicators visible
    [ ] Animations respect prefers-reduced-motion
```

### Phase 2 — Performance

```
PERFORMANCE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Bundle size:
    [ ] No unnecessary large dependencies added
    [ ] Tree shaking effective (named imports used)
    [ ] Code splitting for route-level chunks
    [ ] Dynamic imports for heavy components
[ ] Rendering:
    [ ] No unnecessary re-renders (memoization used)
    [ ] Virtual scrolling for long lists
    [ ] Images lazy-loaded and properly sized
    [ ] Web fonts optimized (subset, display: swap)
[ ] Network:
    [ ] API calls debounced/throttled where appropriate
    [ ] Data fetching uses caching (SWR, React Query)
    [ ] No waterfall request patterns
    [ ] Assets use CDN and proper cache headers
```

### Phase 3 — UX Consistency

```
UX REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Design system:
    [ ] Uses design system components (not custom)
    [ ] Spacing/typography tokens used (not hardcoded)
    [ ] Colors from theme (not hardcoded hex values)
[ ] Responsive design:
    [ ] Works on mobile viewport (320px)
    [ ] Works on tablet viewport (768px)
    [ ] Works on desktop viewport (1024px+)
    [ ] Touch targets minimum 44x44px on mobile
[ ] User experience:
    [ ] Loading states shown
    [ ] Error states handled gracefully
    [ ] Empty states designed
    [ ] Form validation provides clear feedback
    [ ] Confirmation for destructive actions
```

### Phase 4 — Code Quality

```
FRONTEND CODE QUALITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Component architecture:
    [ ] Components are focused (single responsibility)
    [ ] Props interface well-defined (TypeScript types)
    [ ] State management appropriate (local vs global)
    [ ] Side effects isolated (useEffect cleanup)
[ ] Testing:
    [ ] Unit tests for logic/utilities
    [ ] Component tests for interactions
    [ ] Snapshot tests for regressions (if used)
    [ ] E2E tests for critical user flows
[ ] Security:
    [ ] No dangerouslySetInnerHTML / v-html with user data
    [ ] User input sanitized before rendering
    [ ] No sensitive data in client-side storage
    [ ] CSRF protection in place
```

## Output Format

Produce a frontend review report with:
1. **Accessibility compliance** (WCAG level achieved)
2. **Performance impact** (bundle size delta, render performance)
3. **UX consistency** (design system compliance score)
4. **Code quality findings** (by category and severity)
5. **Cross-browser concerns** if any
