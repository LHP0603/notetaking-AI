# Auto-Hiding AppBar Implementation Guide

## Overview

This document provides instructions for replacing in-body screen titles with proper AppBars that automatically hide when scrolling. The implementation applies to multiple screens in the Voicely app and follows Material Design principles with custom styling.

## Table of Contents

1. [Affected Screens](#affected-screens)
2. [Requirements](#requirements)
3. [Implementation Pattern](#implementation-pattern)
4. [Code Examples](#code-examples)
5. [Step-by-Step Implementation](#step-by-step-implementation)
6. [Testing Checklist](#testing-checklist)

---

## Affected Screens

The following screens need to be updated:

1. **Past Transcripts Screen** - `lib/features/transcription/presentation/pages/transcript_list_screen.dart`
2. **Audio Manager Screen** - `lib/features/audio_manager/presentation/pages/audio_manager_page.dart` (when created)
3. **Profile Screen** - `lib/features/profile/presentation/pages/profile_screen.dart`

---

## Requirements

### AppBar Styling

- **Background Color**: Must match scaffold background (`Color(0xFF101822)`)
- **Elevation**: Set to `0` (no shadow)
- **Title Alignment**: Centered
- **Back Button**: Not required (hide with `automaticallyImplyLeading: false`)
- **Scroll Behavior**: Auto-hide when user scrolls down

### Visual Consistency

- Maintain existing color scheme
- Preserve responsive padding
- Smooth hide/show animations
- No visual glitches during transitions

---

## Implementation Pattern

### Core Components

1. **ScrollController**: Track scroll position
2. **SliverAppBar**: Material widget with auto-hide capability
3. **NestedScrollView** or **CustomScrollView**: Container for sliver components

### Key Properties

```dart
SliverAppBar(
  backgroundColor: Color(0xFF101822),    // Match scaffold background
  elevation: 0,                          // No shadow
  centerTitle: true,                     // Center the title
  automaticallyImplyLeading: false,      // Hide back button
  floating: true,                        // Show on scroll up
  snap: true,                            // Snap to visible/hidden
  pinned: false,                         // Don't pin at top
  title: Text('Screen Title'),
)
```

---

## Code Examples

### Example 1: Past Transcripts Screen (Basic Implementation)

**Before:**
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: const Color(0xFF101822),
    body: SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Title
                const Expanded(
                  child: Text(
                    'Past Transcripts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              ),
              child: Column(
                // Content widgets...
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**After:**
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: const Color(0xFF101822),
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          // AppBar that auto-hides
          SliverAppBar(
            backgroundColor: const Color(0xFF101822),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            floating: true,
            snap: true,
            pinned: false,
            title: const Text(
              'Past Transcripts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 24),
                // Folders section
                _buildFoldersSection(),
                const SizedBox(height: 24),
                // Recent Transcripts section
                _buildRecentTranscriptsSection(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Example 2: Profile Screen (With Action Buttons)

**Before:**
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final user = _mockUser;

  return Scaffold(
    backgroundColor: const Color(0xFF101822),
    body: SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => _onBackPressed(context),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // Title
                const Expanded(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Logout button
                GestureDetector(
                  onTap: () => _onLogoutPressed(context),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              ),
              child: Column(
                // Content widgets...
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**After:**
```dart
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final user = _mockUser;

  return Scaffold(
    backgroundColor: const Color(0xFF101822),
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          // AppBar with action buttons
          SliverAppBar(
            backgroundColor: const Color(0xFF101822),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            floating: true,
            snap: true,
            pinned: false,
            leading: GestureDetector(
              onTap: () => _onBackPressed(context),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => _onLogoutPressed(context),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                // Profile avatar section
                ProfileAvatar(
                  name: user.name,
                  imageUrl: user.avatarUrl,
                  onEditPressed: () => _onEditAvatarPressed(context),
                ),
                const SizedBox(height: 24),
                // Rest of content...
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Example 3: Audio Manager Screen (With TabBar)

**Implementation for screen with TabBar:**

```dart
class AudioManagerPage extends StatefulWidget {
  const AudioManagerPage({super.key});

  @override
  State<AudioManagerPage> createState() => _AudioManagerPageState();
}

class _AudioManagerPageState extends State<AudioManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // AppBar
              SliverAppBar(
                backgroundColor: const Color(0xFF101822),
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                floating: true,
                snap: true,
                pinned: false,
                title: const Text(
                  'Audio Manager',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              // TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[500],
                    tabs: const [
                      Tab(text: 'Upload'),
                      Tab(text: 'Tasks'),
                      Tab(text: 'Pending'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildUploadTab(screenWidth),
              _buildTasksTab(screenWidth),
              _buildPendingTab(screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTab(double screenWidth) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Upload tab content...
            ]),
          ),
        ),
      ],
    );
  }

  // Similar for other tabs...
}

// Helper class for TabBar in NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF101822),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
```

---

## Step-by-Step Implementation

### Step 1: Update Past Transcripts Screen

**File:** `lib/features/transcription/presentation/pages/transcript_list_screen.dart`

1. **Remove the existing header Row** from inside the Column
2. **Replace Column with CustomScrollView**
3. **Add SliverAppBar** as first sliver
4. **Convert content to SliverList** or **SliverPadding + SliverList**
5. **Test scrolling behavior**

**Key Changes:**
```dart
// Before: body: SafeArea(child: Column([Header, Content]))
// After:  body: SafeArea(child: CustomScrollView([SliverAppBar, SliverContent]))
```

### Step 2: Update Profile Screen

**File:** `lib/features/profile/presentation/pages/profile_screen.dart`

1. **Remove the existing header Row** from inside the Column
2. **Replace Column with CustomScrollView**
3. **Add SliverAppBar** with leading (back button) and actions (logout button)
4. **Convert content to SliverList**
5. **Adjust padding** if needed
6. **Test all button interactions**

**Special Considerations:**
- Profile screen has back button (use `leading` property)
- Profile screen has logout button (use `actions` property)
- Ensure buttons still work after conversion

### Step 3: Implement Audio Manager Screen

**File:** `lib/features/audio_manager/presentation/pages/audio_manager_page.dart`

1. **Use NestedScrollView** (required for TabBar)
2. **Add SliverAppBar** in `headerSliverBuilder`
3. **Add TabBar** as SliverPersistentHeader (pinned)
4. **Convert tab contents** to use CustomScrollView
5. **Test tab switching and scrolling**

**Special Considerations:**
- Use `NestedScrollView` instead of `CustomScrollView`
- TabBar should remain visible (pinned: true)
- AppBar should auto-hide (pinned: false, floating: true, snap: true)

### Step 4: Widget Conversion Guidelines

**Converting SingleChildScrollView content to SliverList:**

```dart
// Before:
SingleChildScrollView(
  child: Column(
    children: [
      Widget1(),
      Widget2(),
      Widget3(),
    ],
  ),
)

// After:
SliverList(
  delegate: SliverChildListDelegate([
    Widget1(),
    Widget2(),
    Widget3(),
  ]),
)
```

**Alternative using SliverChildBuilderDelegate:**

```dart
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      // Build each item
      return items[index];
    },
    childCount: items.length,
  ),
)
```

---

## SliverAppBar Properties Explained

### Required Properties

```dart
SliverAppBar(
  // Background color matching scaffold
  backgroundColor: const Color(0xFF101822),
  
  // Remove shadow
  elevation: 0,
  
  // Center the title
  centerTitle: true,
  
  // Hide default back button
  automaticallyImplyLeading: false,
  
  // Auto-hide behavior
  floating: true,   // Show when scrolling up
  snap: true,       // Snap to fully visible/hidden
  pinned: false,    // Don't stay at top
  
  // Title widget
  title: const Text(
    'Screen Title',
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
)
```

### Optional Properties

```dart
SliverAppBar(
  // Custom leading widget (e.g., back button)
  leading: IconButton(
    icon: const Icon(Icons.chevron_left),
    onPressed: () {},
  ),
  
  // Action buttons on the right
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () {},
    ),
  ],
  
  // Bottom widget (e.g., TabBar)
  bottom: TabBar(
    tabs: [
      Tab(text: 'Tab 1'),
      Tab(text: 'Tab 2'),
    ],
  ),
  
  // Expanded height (for large headers)
  expandedHeight: 200,
  
  // Flexible space (for custom header content)
  flexibleSpace: FlexibleSpaceBar(
    title: Text('Title'),
    background: Image.network('url'),
  ),
)
```

---

## Scroll Behavior Configuration

### Auto-Hide Behavior Options

| Property | Value | Behavior |
|----------|-------|----------|
| `pinned` | `false` | AppBar can scroll away completely |
| `floating` | `true` | AppBar appears when scrolling up |
| `snap` | `true` | AppBar snaps to visible/hidden (no partial state) |

**Recommended Combination:**
```dart
floating: true,
snap: true,
pinned: false,
```

**Alternative (Always Visible):**
```dart
floating: false,
snap: false,
pinned: true,  // AppBar always visible at top
```

**Alternative (Manual Control):**
```dart
floating: false,
snap: false,
pinned: false,  // Completely manual with ScrollController
```

---

## Common Patterns

### Pattern 1: Simple Screen (No Tabs, No Actions)

```dart
Scaffold(
  backgroundColor: const Color(0xFF101822),
  body: SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF101822),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          floating: true,
          snap: true,
          pinned: false,
          title: const Text('Title'),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            // Content widgets
          ]),
        ),
      ],
    ),
  ),
)
```

### Pattern 2: Screen with Action Buttons

```dart
SliverAppBar(
  backgroundColor: const Color(0xFF101822),
  elevation: 0,
  centerTitle: true,
  automaticallyImplyLeading: false,
  floating: true,
  snap: true,
  pinned: false,
  leading: IconButton(
    icon: const Icon(Icons.chevron_left),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text('Title'),
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {},
    ),
  ],
)
```

### Pattern 3: Screen with TabBar

```dart
NestedScrollView(
  headerSliverBuilder: (context, innerBoxIsScrolled) {
    return [
      SliverAppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        floating: true,
        snap: true,
        pinned: false,
        title: const Text('Title'),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: _SliverAppBarDelegate(
          TabBar(
            controller: _tabController,
            tabs: [...],
          ),
        ),
      ),
    ];
  },
  body: TabBarView(
    controller: _tabController,
    children: [...],
  ),
)
```

---

## Troubleshooting

### Issue 1: Content Jumps When Scrolling

**Cause:** Incorrect sliver structure or padding

**Solution:** Ensure consistent padding in SliverPadding and remove duplicate spacing

### Issue 2: AppBar Doesn't Hide

**Cause:** Incorrect scroll physics or missing properties

**Solution:** Verify `floating: true`, `snap: true`, `pinned: false`

### Issue 3: White Flash on Background

**Cause:** Scaffold background doesn't match AppBar

**Solution:** Ensure both use `Color(0xFF101822)`

### Issue 4: Buttons Don't Work in AppBar

**Cause:** Wrong widget type or gesture detector issue

**Solution:** Use `IconButton` or wrap in `GestureDetector` with proper `onTap`

### Issue 5: TabBar Scrolls Away with AppBar

**Cause:** TabBar in wrong location

**Solution:** Use `SliverPersistentHeader` with `pinned: true` for TabBar

---

## Testing Checklist

### Visual Testing

- [ ] AppBar background matches scaffold (`Color(0xFF101822)`)
- [ ] No shadow/elevation visible
- [ ] Title is centered
- [ ] No back button (unless specified)
- [ ] Action buttons align properly
- [ ] Smooth hide/show animation
- [ ] No white flashes or color mismatches
- [ ] Content padding is consistent

### Functional Testing

- [ ] AppBar hides when scrolling down
- [ ] AppBar shows when scrolling up
- [ ] Snaps to fully visible/hidden (no partial state)
- [ ] Back button works (if present)
- [ ] Action buttons work (if present)
- [ ] TabBar remains visible (if present)
- [ ] Content scrolls smoothly
- [ ] No performance issues

### Responsive Testing

- [ ] Works on small screens (< 600px width)
- [ ] Works on large screens (> 600px width)
- [ ] Title doesn't overflow
- [ ] Padding adjusts correctly
- [ ] Buttons remain accessible

---

## Performance Considerations

1. **Use SliverChildBuilderDelegate** for long lists instead of SliverChildListDelegate
2. **Avoid rebuilding** entire sliver list on state changes
3. **Use const constructors** where possible
4. **Minimize widget rebuilds** in AppBar title/actions
5. **Test with many items** to ensure smooth scrolling

---

## Best Practices

1. **Consistent Styling**: Use same AppBar styling across all screens
2. **Semantic Actions**: Place primary actions on right, navigation on left
3. **Accessibility**: Ensure buttons have proper semantic labels
4. **Safe Area**: Always wrap CustomScrollView in SafeArea
5. **Color Consistency**: Match all background colors to avoid visual artifacts

---

## Migration Checklist

For each screen being updated:

- [ ] Identify current header structure
- [ ] Note any action buttons or special widgets
- [ ] Replace Column with CustomScrollView
- [ ] Add SliverAppBar with correct properties
- [ ] Convert content to SliverList
- [ ] Test scrolling behavior
- [ ] Verify all buttons work
- [ ] Check responsive behavior
- [ ] Test on real device
- [ ] Update any related tests

---

## Additional Resources

### Flutter Documentation

- [SliverAppBar Class](https://api.flutter.dev/flutter/material/SliverAppBar-class.html)
- [CustomScrollView Class](https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html)
- [NestedScrollView Class](https://api.flutter.dev/flutter/widgets/NestedScrollView-class.html)
- [Slivers Overview](https://docs.flutter.dev/ui/layout/scrolling/slivers)

### Code References

- Existing implementation: `lib/features/recording/presentation/pages/recording_page.dart`
- Theme constants: `lib/core/theme/app_theme.dart`
- Color constants: `lib/core/constants/app_constants.dart`

---

**End of Document**
