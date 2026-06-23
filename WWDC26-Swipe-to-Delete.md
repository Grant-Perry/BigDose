# WWDC '26 Swipe-to-Delete in SwiftUI

Portable guide for adopting Apple’s iOS 27 swipe-action APIs in any SwiftUI app. Written from the BigDose implementation; copy this file and the helper Swift into other repos as needed.

**Primary source:** [What’s new in SwiftUI — WWDC26 session 269](https://developer.apple.com/videos/play/wwdc2026/269/) (chapter ~18:12)

---

## TL;DR

| Before iOS 27 | iOS 27+ |
|---------------|---------|
| `swipeActions` only worked inside `List` | `swipeActions` works on **any row view** |
| Custom `ScrollView` / `LazyVStack` layouts needed workarounds (`contextMenu`, custom gestures, or forcing `List`) | Add `.swipeActionsContainer()` on the scroll parent to get List-like coordination |
| No presentation callback | Optional `onPresentationChanged:` closure on `swipeActions` |

**Minimum adoption:** put delete actions on rows with `.swipeActions`, and put `.swipeActionsContainer()` on the parent scroll container when not using `List`.

---

## What Apple Changed

### 1. Swipe actions escape `List`

Previously, if you wanted GlassCard-style rows, custom spacing, or a non-list layout, you could not use native swipe-to-delete without restructuring as a `List`.

In iOS 27, the same `swipeActions` modifier attaches to individual row views inside `ScrollView`, `LazyVStack`, `LazyVGrid`, or custom layouts.

### 2. `swipeActionsContainer()` coordinates the container

`List` already handled:

- Dismissing one row’s actions when another row is swiped
- Mutual exclusion across visible rows
- Scroll/gesture coordination

For non-`List` containers, apply **`swipeActionsContainer()`** to the parent (typically the `ScrollView` or stack that holds the rows). On `List`, this modifier is a **no-op** — safe to use everywhere, but only required outside `List`.

### 3. Optional presentation callback

New overload:

```swift
.swipeActions(
    edge: .trailing,
    allowsFullSwipe: true,
    onPresentationChanged: { isPresented in
        // true when actions become visible, false when dismissed
    }
) {
    Button(role: .destructive) { … } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

Use this to dim a row, hide chrome, or update accessibility while actions are showing.

---

## Migration Patterns

### Pattern A — Already using `List`

No container change needed. Add swipe actions per row:

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}
```

### Pattern B — Custom scroll layout (GlassCards, LazyVStack, etc.)

**Row:** attach `swipeActions`  
**Parent:** attach `swipeActionsContainer()`

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemRow(item: item)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
    .padding()
}
.swipeActionsContainer() // iOS 27+
```

### Pattern C — Replace long-press-only delete

Many apps used `contextMenu { Button("Delete", role: .destructive) … }` because swipe was unavailable outside `List`. Prefer swipe on iOS 27+ and keep context menu as fallback on older OS versions (see availability section below).

---

## Availability & Deployment Target

These APIs ship in the **iOS 27 SDK** (Xcode 27, “2027 releases” in Apple’s WWDC naming).

| API | Availability |
|-----|--------------|
| `swipeActions` inside `List` | iOS 15+ (unchanged) |
| `swipeActions` on arbitrary views + `swipeActionsContainer()` | **iOS 27+** |

If your app’s deployment target is **below iOS 27** (e.g. iOS 26.6):

- **`List` rows:** swipe delete works today — no gate needed.
- **`ScrollView` / custom rows:** gate both the row modifier and `swipeActionsContainer()` behind `#available(iOS 27.0, *)`, and keep `contextMenu` (or another fallback) on older OS versions.

---

## Drop-in Helper (copy into DesignSystem)

Create something like `SwipeToDelete.swift` in your design system or shared UI module:

```swift
import SwiftUI

extension View {
    /// Trailing destructive swipe-to-delete using the system affordance.
    func appSwipeToDelete(action: @escaping @MainActor () -> Void) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: action) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    /// Coordinates swipe actions across rows in custom scroll containers.
    /// No-op on `List` (List coordinates automatically).
    @ViewBuilder
    func appSwipeActionsContainer() -> some View {
        if #available(iOS 27.0, *) {
            swipeActionsContainer()
        } else {
            self
        }
    }

    /// Swipe-to-delete on iOS 27+; long-press delete menu on earlier releases.
    @ViewBuilder
    func appDeletable(action: @escaping @MainActor () -> Void) -> some View {
        if #available(iOS 27.0, *) {
            appSwipeToDelete(action: action)
        } else {
            contextMenu {
                Button("Delete", role: .destructive, action: action)
            }
        }
    }
}
```

Rename the `app*` prefixes to match your project (e.g. `bigDoseSwipeToDelete`).

### Usage cheat sheet

| Container | Row modifier | Parent modifier |
|-----------|--------------|-----------------|
| `List` | `.appSwipeToDelete { … }` | none |
| `ScrollView` + custom rows | `.appDeletable { … }` | `.appSwipeActionsContainer()` |
| `ScrollView`, iOS 27 only | `.appSwipeToDelete { … }` | `.appSwipeActionsContainer()` |

---

## Adoption Checklist (another repo)

1. **Inventory** — search for `contextMenu`, `onDelete`, custom swipe gestures, and `List` rows that should delete but don’t.
2. **Add helper** — copy the extension above; adjust naming.
3. **`List` screens** — add `.appSwipeToDelete` on each deletable row; wire delete + any side effects (HealthKit, sync, etc.).
4. **`ScrollView` / custom card screens** — add `.appDeletable` on rows and `.appSwipeActionsContainer()` on the scroll view.
5. **Delete logic** — keep delete in one place per entity (view model or private method); swipe and edit-sheet delete should call the same function.
6. **Test on iOS 27** — swipe left on a row; full swipe should delete when `allowsFullSwipe: true`.
7. **Test on minimum deployment target** — confirm fallback (context menu) still works where gated.
8. **Optional** — use `onPresentationChanged` if rows need visual feedback while actions are open.

---

## Common Pitfalls

1. **Forgot `swipeActionsContainer()`** — swipe actions on custom scroll rows may not behave correctly without it on iOS 27.
2. **Applied container inside the row** — `swipeActionsContainer()` belongs on the **parent** scroll/stack, not each row.
3. **Button inside row fights swipe** — tappable `Button` rows still work; swipe is orthogonal. If gestures conflict, check hit testing and use `.buttonStyle(.plain)` where appropriate.
4. **Delete only in edit sheet** — ledger/summary sheets often had tap-to-edit but no list delete; add swipe there too.
5. **Side effects** — supplements, synced entities, etc. need the same cleanup in swipe delete as in edit-sheet delete (e.g. HealthKit removal before `modelContext.delete`).

---

## BigDose Reference Implementation

Files in this repo:

| File | Role |
|------|------|
| `BigDose/DesignSystem/BigDoseSwipeToDelete.swift` | Shared modifiers |
| `BigDose/Features/History/DailyIULedgerSheets.swift` | Today’s Supplements / Today’s Food (`List`) |
| `BigDose/Features/Profile/FoodLogView.swift` | Food log (`ScrollView` + container) |
| `BigDose/Features/Profile/SupplementLogView.swift` | Supplement log |
| `BigDose/Features/Profile/LabResultsView.swift` | Lab results |

---

## Raising deployment target to iOS 27

If you drop iOS 26 support:

- Remove `#available` branches in the helper.
- Use `.appSwipeToDelete` everywhere instead of `.appDeletable`.
- Keep `.appSwipeActionsContainer()` on all non-`List` scroll parents.

---

## Related WWDC '26 APIs (same session)

Not required for delete, but often adopted together:

- **Reorderable containers** — drag-to-reorder in `List`, `LazyVGrid`, etc. via `reorderable` + `reorderContainer`.
- **Confirmation dialogs with item binding** — same `$item` pattern as `.sheet(item:)`.

---

## Further Reading

- [WWDC26 SwiftUI guide](https://developer.apple.com/wwdc26/guides/swiftui/)
- [What’s new in SwiftUI — session 269](https://developer.apple.com/videos/play/wwdc2026/269/)
- [swipeActionsContainer()](https://developer.apple.com/documentation/swiftui/view/swipeactionscontainer()) (iOS 27)
- [swipeActions with onPresentationChanged](https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:onpresentationchanged:)) (iOS 27)
