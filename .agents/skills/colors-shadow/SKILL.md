---
name: colors-shadow
description: Design practical web UIs using a restrained color system, clear hierarchy, and purposeful depth. Use these rules when creating, reviewing, or improving UI designs.
---

# UI Design System

## Core Rule

Create interfaces that are **simple, coherent, hierarchical, dimensional, and usable**.

Do not add color, shadows, gradients, borders, or decoration unless they improve hierarchy, interaction, or depth.

---

## 1. Color

### DO

- Use **neutral colors** for backgrounds, surfaces, text, and most borders.
- Use **one primary/brand color** for important actions and character.
- Use **semantic colors** only when they communicate states such as success, warning, or error.
- Think in **shades**, not isolated colors.
- Build related shades by changing lightness while keeping the palette coherent.
- Prefer **OKLCH** for generating UI color scales when possible.
- Keep saturation/chroma restrained unless the design clearly needs stronger color.
- Use CSS variables/tokens for all theme colors.
- Define both light and dark themes.
- Check primary and secondary colors in hover/active states.

### DON'T

- Don't use many unrelated colors.
- Don't make every element colorful.
- Don't rely on arbitrary hex values for every shade.
- Don't use maximum-brightness text everywhere.
- Don't let borders compete with the content.
- Don't treat light mode as an afterthought.

---

## 2. Surface Hierarchy

Use differences in surface lightness to create layers.

Typical hierarchy:

**Page → Section/Card → Important/Interactive Element**

For dark themes:
- Base/page = darkest surface.
- Cards/sections = slightly lighter.
- Important/raised elements = lighter again.

For light themes:
- Use the same relative hierarchy, but retune the values visually.
- A darker page background can make important cards stand out.
- De-emphasize secondary cards, tables, and graphs when everything competes for attention.

### DO

- Use lighter surfaces to make important elements feel closer/raised.
- Use darker surfaces to make elements feel deeper/recessed.
- Remove borders when surface contrast already provides enough separation.

### DON'T

- Don't give every component the same surface level.
- Don't make every element visually prominent.

---

## 3. Typography

Create hierarchy through contrast, size, weight, and placement.

### DO

- Use stronger contrast for headings and important content.
- Use muted text for secondary information.
- Make important text visibly more important.
- Rework typography when an important element lacks hierarchy.

### DON'T

- Don't make all text equally strong.
- Don't use pure white/lightest text everywhere in dark mode; it can feel harsh.
- Don't add headings when the section is already self-explanatory.

---

## 4. Depth & Shadows

Depth is a high-impact way to improve a flat UI.

### Basic depth recipe

1. Create **3–4 coherent shades** of the same base color.
2. Layer those shades according to importance.
3. Add restrained shadows/highlights.

### Shadow rules

- Use transparency/alpha.
- Prefer a **shorter, darker shadow** combined with a **lighter, softer/longer shadow** for realistic depth.
- Use small shadows by default.
- Increase shadow size only when the element needs stronger elevation.
- Use a lighter top highlight/inset shadow and darker lower shadow to suggest light coming from above.
- Use inset shadows to make controls feel recessed.
- Use stronger hover shadows when hover elevation is useful, especially in light themes.

### DON'T

- Don't use huge shadows by default.
- Don't stack effects just to make a UI look fancy.
- Don't use depth on every element equally.

---

## 5. Light Direction

Use a consistent visual light source, normally from above.

### DO

- Keep top areas/highlights lighter.
- Use a lighter top border/highlight with gradients when appropriate.
- Make the bottom/deeper areas relatively darker.
- Retune highlights and borders for light mode instead of blindly copying dark-mode values.

### DON'T

- Don't use conflicting light directions.
- Don't copy dark-theme effects into light mode without visual adjustment.

---

## 6. Components

### Navigation

- Use multiple shades of the same color to create layers.
- Make the selected tab clearly stand out.
- Use subtle depth rather than excessive decoration.

### Cards

- Give important cards a lighter/raised surface.
- Use rounded corners, appropriate padding, and restrained shadows.
- Use larger elevation only when the context requires it.

### Dropdowns / Primary Controls

- Highlight important interactive controls.
- A subtle gradient plus top highlight/inset shadow can add depth.
- Keep the effect restrained.

### Radio Groups / Option Cards

- Group related options inside a clear surface.
- Add spacing.
- Highlight options.
- Make the selected option clearly dominant.
- Use a small elevation effect for the selected option.
- Add icons only when they improve recognition.

### Progress Bars

- Use inset shadows to make the track feel recessed.
- Let the progress indicator feel slightly elevated above the track.

### Dashboards

- Establish a clear background → card → important element hierarchy.
- De-emphasize secondary tables/graphs.
- Use surface contrast before adding borders.
- Use shadows selectively to raise/lower elements.
- Recess tables or containers when the information architecture benefits from it.

---

## 7. Gradients & Highlights

### DO

- Build gradients from existing palette shades.
- Keep gradients subtle by default.
- Reveal/strengthen gradients on hover when useful.
- Pair top highlights with gradients to reinforce the light source.

### DON'T

- Don't use gradients as decoration without purpose.
- Don't make gradients overpower text or controls.

---

## 8. Interaction States

Every important interactive element should have clear visual states:

- Default
- Hover
- Active/Pressed
- Selected
- Focus
- Disabled
- Error/Success/Warning when relevant

Use **shade, contrast, elevation, or subtle shadow changes** to communicate state.

Do not change the whole visual language between states.

---

## 9. Design Priorities

When improving an existing UI, work in this order:

1. **Hierarchy**
2. **Color/surface system**
3. **Typography**
4. **Spacing/layout**
5. **Depth/elevation**
6. **Interaction states**
7. **Decorative polish**

Fix the biggest visual problem first.

Do not spend excessive time perfecting tiny details when the improvement has little impact.

---

## 10. Agent Behavior

When designing or improving a UI:

1. Inspect the existing hierarchy.
2. Identify the primary user action.
3. Establish a small color/surface system.
4. Create light and dark theme tokens.
5. Establish typography hierarchy.
6. Assign surface levels to elements.
7. Add restrained depth and shadows.
8. Define interaction states.
9. Check both light and dark themes.
10. Remove unnecessary effects and decoration.
11. Review the final UI for clarity, consistency, and visual hierarchy.

### Final decision rule

If an effect does not improve **hierarchy, usability, interaction, or depth**, remove it.

If two solutions work equally well, choose the **simpler** one.
