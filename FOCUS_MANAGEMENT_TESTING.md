# VimEditDialog Focus Management - Testing Guide

## Overview
This document describes the focus management implementation for VimEditDialog and provides a testing checklist.

## Implementation Summary

### Changes Made

**1. VimEditOverlay (vim_edit_overlay.dart)**
- Converted from `ConsumerWidget` to `ConsumerStatefulWidget`
- Added `_focusNode` to manage focus explicitly
- Uses `WidgetsBinding.instance.addPostFrameCallback` to request focus when dialog becomes visible
- Passes `focusNode` to `VimTerminalView` instead of relying on `autofocus`

**2. VimEditService (vim_edit_service.dart)**
- Added `previousFocusNode` field to `VimEditState` to store the focus before opening
- In `open()`: Captures current focus via `FocusManager.instance.primaryFocus`
- In `_onSessionExit()`: Restores previous focus if still valid using `canRequestFocus` check

### Focus Flow

```
User presses Cmd+Shift+E
  ↓
VimEditService.open() captures current focus (terminal)
  ↓
Dialog becomes visible (isVisible = true)
  ↓
VimEditOverlay detects visibility change
  ↓
addPostFrameCallback requests focus on _focusNode
  ↓
Focus transfers to Vim editor
  ↓
User exits Vim (:q, :wq, etc.)
  ↓
_onSessionExit() restores previous focus
  ↓
Focus returns to terminal
```

## Testing Checklist

### Task 3: Focus Management Testing

#### Basic Focus Transfer
- [ ] **Test 1**: Open dialog with Cmd+Shift+E
  - Expected: Dialog opens and focus immediately transfers to Vim
  - Verify: Type characters directly without clicking - they should appear in Vim

- [ ] **Test 2**: Close dialog and return focus
  - Steps: 
    1. Start typing in terminal
    2. Press Cmd+Shift+E (opens Vim)
    3. Exit Vim with `:q`
  - Expected: Focus returns to terminal, can continue typing

- [ ] **Test 3**: Multiple open/close cycles
  - Steps: Open and close Vim dialog 5 times in succession
  - Expected: Focus correctly transfers each time without degradation

#### Keyboard Shortcut Conflicts

- [ ] **Test 4**: Vim shortcuts don't trigger app shortcuts
  - In Vim, test these common shortcuts:
    - `:w` (save) - should not trigger any app action
    - `:q` (quit) - should close Vim, not the app
    - `dd` (delete line) - should work in Vim
    - `yy` (yank line) - should work in Vim
    - `i`, `a`, `o` (insert modes) - should work in Vim
  - Expected: All Vim shortcuts work normally

- [ ] **Test 5**: App shortcuts while Vim is open
  - With Vim dialog open, test:
    - Cmd+P (Command Palette) - **Document behavior**: Should it open or be blocked?
    - Cmd+Shift+P - **Document behavior**: Should it open or be blocked?
    - Cmd+W (close tab) - **Document behavior**: Should it close or be blocked?
  - Expected: Determine if these should be intercepted or allowed

- [ ] **Test 6**: Escape key behavior
  - Press Escape in Vim
  - Expected: Should exit insert mode in Vim, NOT close the dialog

#### Edge Cases

- [ ] **Test 7**: No previous focus
  - Steps: Open app fresh, immediately press Cmd+Shift+E before clicking anything
  - Expected: Dialog opens with focus, closes gracefully without errors

- [ ] **Test 8**: Previous focus widget destroyed
  - Steps: 
    1. Focus on a terminal tab
    2. Open Vim (Cmd+Shift+E)
    3. Close the terminal tab (from another window/method if possible)
    4. Exit Vim
  - Expected: No crash, focus goes to a reasonable default

- [ ] **Test 9**: Rapid open/close
  - Steps: Quickly press Cmd+Shift+E twice in rapid succession
  - Expected: No race conditions, dialog state remains consistent

#### Focus Restoration Accuracy

- [ ] **Test 10**: Focus returns to exact position
  - Steps:
    1. Type partial command in terminal: `echo "test`
    2. Press Cmd+Shift+E
    3. Exit Vim immediately with `:q`
    4. Continue typing: `"`
  - Expected: Cursor position preserved, can complete the command

## Known Issues / Notes

### Potential Shortcut Conflicts
Document any conflicts discovered during testing:

- **Issue**: [Description]
- **Workaround**: [Solution]

### Focus Scope Isolation
If global shortcuts interfere with Vim operation, consider wrapping the dialog in a `FocusScope`:

```dart
FocusScope(
  child: VimTerminalView(...),
)
```

This would create an isolated focus scope that prevents parent shortcuts from triggering.

## Future Improvements

1. **Focus Scope Isolation**: If testing reveals shortcut conflicts, implement `FocusScope` wrapper
2. **Focus Indicator**: Add visual indicator when Vim editor has focus
3. **Focus Loss Handling**: Handle cases where focus is lost unexpectedly (e.g., system dialog appears)
4. **Accessibility**: Ensure screen readers properly announce focus changes

## Testing Results

### Date: [Fill in after testing]
### Tester: [Your name]

| Test # | Status | Notes |
|--------|--------|-------|
| 1      |        |       |
| 2      |        |       |
| 3      |        |       |
| 4      |        |       |
| 5      |        |       |
| 6      |        |       |
| 7      |        |       |
| 8      |        |       |
| 9      |        |       |
| 10     |        |       |

### Summary
[Overall assessment of focus management implementation]

### Recommended Actions
- [ ] Action item 1
- [ ] Action item 2
