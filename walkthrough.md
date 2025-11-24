# Paste in Overwrite Mode Fix

## Problem
When the user was in "Overwrite Mode" and pasted data (e.g. via Cmd+V), the application would **insert** the data at the cursor position instead of **overwriting** the existing data. This was inconsistent with the expected behavior of an overwrite mode.

## Solution
I modified the `HexDocument` and `HexGridView` to support bulk replacement of data.

### Changes

1.  **`HexDocument.swift`**:
    *   Added a new method `replace(bytes: [UInt8], at index: Int, undoManager: UndoManager?)`.
    *   This method calculates how much of the pasted data can replace existing data and how much needs to be appended (if the paste extends beyond the file end).
    *   It implements undo support by grouping the "delete inserted" and "restore replaced" operations.

2.  **`HexGridView.swift`**:
    *   Updated `pasteFromClipboard()` to check `isOverwriteMode`.
    *   If `isOverwriteMode` is true, it calls the new `document.replace(bytes:...)` method.
    *   If `isOverwriteMode` is false (Insert Mode), it continues to use `document.insert(bytes:...)`.

## Verification

### Manual Verification Steps
1.  Open the HexEditor.
2.  Toggle "Overwrite Mode" (if not already on).
3.  Select a byte in the middle of the file.
4.  Copy some data (e.g. "AA BB").
5.  Paste the data.
6.  **Expected Result**: The bytes at the cursor position should be replaced by "AA BB". The file size should not change (unless pasting at the very end extends the file).
7.  Toggle "Insert Mode".
8.  Paste the same data.
9.  **Expected Result**: The bytes "AA BB" should be inserted at the cursor position, shifting subsequent bytes. The file size should increase.

### Code Verification
The `replace` method logic handles edge cases:
- **Partial Overwrite**: If pasting 5 bytes at 2 bytes before EOF, it replaces the last 2 bytes and appends the remaining 3 bytes.
- **Undo/Redo**: The undo operation correctly restores the original bytes and removes any appended bytes.
