# Premium Design System - iOS-Inspired

## Design Philosophy

This design system is inspired by Apple's iOS design guidelines, focusing on:
- **Elegance**: Clean, minimal, sophisticated
- **Readability**: High contrast, clear hierarchy
- **Softness**: Rounded corners, subtle shadows, smooth transitions
- **Premium Feel**: Warm yellow as primary, refined neutrals

---

## Color Palette

### Primary Colors (Yellow - Premium & Warm)

| Color | Hex | Usage |
|-------|-----|-------|
| Yellow Primary | `#FFD700` | Main brand color, primary buttons, accents |
| Yellow Light | `#FFF8DC` | Light backgrounds, subtle highlights |
| Yellow Dark | `#FFC107` | Dark mode primary, hover states |
| Yellow Accent | `#FFEB3B` | Bright accents, highlights |

**Design Decision**: Chose warm, elegant yellow tones that are premium without being aggressive. The gold (#FFD700) provides luxury feel while remaining readable.

### Neutral Colors (iOS-Inspired Grays)

| Color | Hex | Usage |
|-------|-----|-------|
| White | `#FFFFFF` | Primary background (light mode) |
| Off White | `#FAFAFA` | Secondary backgrounds |
| Gray 50-900 | `#F5F5F5` to `#121212` | Progressive grays for hierarchy |
| Black | `#000000` | Primary background (dark mode) |

**Design Decision**: Used iOS-standard gray scale for consistent, professional appearance.

### Semantic Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Success | `#34C759` | iOS green for success states |
| Warning | `#FF9500` | iOS orange for warnings |
| Error | `#FF3B30` | iOS red for errors |
| Info | `#007AFF` | iOS blue for information |

---

## Typography

### Font Family
- **Primary**: Inter (SF Pro equivalent)
- **Weights**: 400 (Regular), 500 (Medium), 600 (Semibold), 700 (Bold)

### Type Scale

| Style | Size | Weight | Letter Spacing | Line Height | Usage |
|-------|------|--------|----------------|-------------|-------|
| Display Large | 34px | 700 | -0.5 | 1.2 | Hero headlines |
| Display Medium | 28px | 700 | -0.5 | 1.2 | Large headlines |
| Display Small | 22px | 600 | -0.3 | 1.3 | Section headers |
| Headline Large | 32px | 700 | -0.5 | 1.2 | Page titles |
| Headline Medium | 28px | 600 | -0.4 | 1.3 | Section titles |
| Headline Small | 22px | 600 | -0.3 | 1.3 | Subsection titles |
| Title Large | 20px | 600 | -0.2 | 1.4 | Card titles |
| Title Medium | 17px | 600 | 0 | 1.4 | List items |
| Title Small | 15px | 600 | 0.1 | 1.4 | Small titles |
| Body Large | 17px | 400 | 0.1 | 1.5 | Primary body text |
| Body Medium | 15px | 400 | 0.1 | 1.5 | Secondary body text |
| Body Small | 13px | 400 | 0.2 | 1.4 | Captions, hints |
| Label Large | 17px | 600 | 0.3 | 1.2 | Buttons |
| Label Medium | 15px | 600 | 0.3 | 1.2 | Small buttons |
| Label Small | 13px | 600 | 0.3 | 1.2 | Tiny labels |
| Caption | 12px | 400 | 0.3 | 1.3 | Captions |
| Overline | 10px | 500 | 0.5 | 1.2 | Overlines |

**Design Decision**: Negative letter spacing for large text improves readability. Generous line heights (1.4-1.5) ensure comfortable reading.

---

## Spacing System

Based on 8px grid system (iOS standard):

| Name | Size | Usage |
|------|------|-------|
| XS | 4px | Tight spacing |
| SM | 8px | Base unit, small gaps |
| MD | 16px | Standard spacing |
| LG | 24px | Section spacing |
| XL | 32px | Large spacing |
| XXL | 40px | Extra large spacing |
| XXXL | 48px | Maximum spacing |

**Screen Padding**: 20px horizontal, 16px vertical

---

## Border Radius

| Name | Size | Usage |
|------|------|-------|
| Small | 8px | Buttons, inputs |
| Medium | 12px | Cards, containers |
| Large | 16px | Modals, sheets |
| XLarge | 20px | Large containers |
| Circular | 999px | Pills, avatars |

**Design Decision**: Soft, rounded corners (8-16px) create modern, friendly feel without being too playful.

---

## Shadows & Elevation

### Light Mode
- **Subtle**: `0 1px 3px rgba(0,0,0,0.1)` - Cards, inputs
- **Medium**: `0 2px 8px rgba(0,0,0,0.1)` - Elevated cards
- **Strong**: `0 4px 16px rgba(0,0,0,0.15)` - Modals, dialogs

### Dark Mode
- **Subtle**: `0 1px 3px rgba(0,0,0,0.4)` - Cards, inputs
- **Medium**: `0 2px 8px rgba(0,0,0,0.4)` - Elevated cards
- **Strong**: `0 4px 16px rgba(0,0,0,0.5)` - Modals, dialogs

**Design Decision**: Subtle shadows maintain iOS-like flatness while providing depth hierarchy.

---

## Component Specifications

### Buttons

#### Primary Button
- **Background**: Yellow Primary (#FFD700)
- **Text**: Black (#000000)
- **Padding**: 16px horizontal, 16px vertical
- **Border Radius**: 8px
- **Elevation**: 0 (flat design)
- **Font**: Label Large (17px, 600 weight)

#### Secondary Button (Outlined)
- **Background**: Transparent
- **Border**: 1px Gray 300
- **Text**: Text Primary
- **Padding**: 16px horizontal, 16px vertical
- **Border Radius**: 8px

#### Text Button
- **Background**: Transparent
- **Text**: Yellow Primary
- **Padding**: 16px horizontal, 8px vertical
- **Border Radius**: 8px

### Text Fields

- **Background**: Gray 50 (light) / Gray 800 (dark)
- **Border**: 1px Gray 300 (light) / Gray 700 (dark)
- **Focused Border**: 2px Yellow Primary
- **Padding**: 16px all sides
- **Border Radius**: 8px
- **Font**: Body Medium (15px, 400 weight)

### Cards

- **Background**: White (light) / Gray 800 (dark)
- **Border**: 0.5px subtle border
- **Padding**: 16px
- **Border Radius**: 12px
- **Elevation**: 0 (uses border for definition)
- **Margin**: 20px horizontal, 8px vertical

### AppBar

- **Background**: White (light) / Black (dark)
- **Elevation**: 0
- **Title**: Title Large (20px, 600 weight)
- **Icons**: 24px, Text Primary color

### Bottom Navigation Bar

- **Background**: White (light) / Gray 800 (dark)
- **Selected**: Yellow Primary
- **Unselected**: Gray 500
- **Elevation**: 8px (light) / 0 (dark)
- **Label**: 12px, 600 weight (selected), 400 weight (unselected)

---

## Animation Principles

1. **Duration**: 200-300ms for micro-interactions, 300-500ms for transitions
2. **Curve**: `Curves.easeOutCubic` for natural feel
3. **Scale**: Subtle (0.95-1.0) for button presses
4. **Opacity**: Fade transitions (0.0-1.0) for smooth appearance

---

## Accessibility

- **Contrast Ratios**: All text meets WCAG AA standards (4.5:1 minimum)
- **Touch Targets**: Minimum 44x44px (iOS standard)
- **Font Scaling**: Supports dynamic type scaling
- **Color Independence**: Information not conveyed by color alone

---

## Usage Examples

### Light Mode
```dart
Theme.of(context).colorScheme.primary // Yellow Primary
Theme.of(context).colorScheme.surface // White
Theme.of(context).textTheme.headlineLarge // Large headline
```

### Dark Mode
```dart
Theme.of(context).colorScheme.primary // Yellow Dark
Theme.of(context).colorScheme.surface // Black
Theme.of(context).textTheme.headlineLarge // Large headline (white)
```

---

## Implementation Notes

- All colors are defined in `app_colors.dart`
- All text styles are in `app_text_styles.dart`
- All spacing constants are in `app_spacing.dart`
- Theme configuration is in `app_theme.dart`
- Uses Material 3 design system
- Fully supports light and dark modes




