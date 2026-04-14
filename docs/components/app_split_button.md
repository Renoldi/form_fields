# AppSplitButton

Two-part button with primary action and dropdown secondary actions.

## Basic Usage

```dart
AppSplitButton<String>(
  text: 'Add to cart',
  onPressed: () {},
  items: const [
    AppSplitButtonItem(value: 'save', label: 'Save for later'),
  ],
  onSelected: (value) {},
)
```
