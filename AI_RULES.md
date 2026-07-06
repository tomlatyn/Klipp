# Klipp AI Rules

- **Architecture**: The project uses a lightweight custom mini-TCA implementation ([Core/ComposableArchitecture.swift](Klipp/Core/ComposableArchitecture.swift)). Reducers must stay pure; all side effects go through `Effect` and the service classes in `Klipp/Services`.
- **Design System & Styling**:
  - Colors are defined in the asset catalog ([Assets.xcassets](Klipp/Resources/Assets.xcassets)) and referenced as color constants (e.g., `Color.primaryText`, `Color.secondaryText`, `Color.selectionTint`, `Color.divider`).
  - Spacings, corner radii, and typography/fonts are defined and must be used from [AppTheme.swift](Klipp/Core/AppTheme.swift) namespaces:
    - `AppTheme.Spacing.*`
    - `AppTheme.CornerRadius.*`
    - `AppTheme.Fonts.*`
  - The glass/liquid look is applied exclusively through `GlassSurface` ([UI/GlassSurface.swift](Klipp/UI/GlassSurface.swift)). It is the only place in the codebase allowed to branch on `#available(macOS 26.0, *)` — native Liquid Glass on macOS 26+, custom material glass on macOS 14–15.
- **Localization**: All user-facing strings must go through the String Catalog ([Localizable.xcstrings](Klipp/Resources/Localizable.xcstrings)); no hardcoded user-facing strings outside SwiftUI/`String(localized:)` literals that feed the catalog.
- **MARK Comments Formatting**: All `// MARK:` comments in Swift source files must be formatted with exactly one vertically empty line above and one vertically empty line below them.
- **Inline Comments**: No inline code comments should be used. Only file header comments and formatting-compliant MARK comments are allowed.
