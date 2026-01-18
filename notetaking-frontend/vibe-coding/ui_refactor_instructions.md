# UI Refactoring Instructions for Recording Page

This document provides instructions for refactoring the `RecordingPage` UI to implement a curved bottom navigation bar, replacing the existing bottom action buttons.

## 1. Dependencies

Add the `curved_navigation_bar` package to your `pubspec.yaml`:

```yaml
dependencies:
  curved_navigation_bar: ^1.0.3 # Check for the latest version on pub.dev
```

## 2. Refactoring Goals

*   **Convert to StatefulWidget:** Change `RecordingPage` from `StatelessWidget` to `StatefulWidget` to manage the navigation bar state.
*   **Implement CurvedNavigationBar:** Replace the bottom row of buttons with the `CurvedNavigationBar`.
*   **Map Actions:**
    *   **Folder (Index 0):** Navigate to History (`_onHistoryPressed`).
    *   **Upload (Index 1):** Import Audio (`_onImportPressed`).
    *   **Record (Index 2 - Center):** Toggle Recording (Start/Stop/Resume) - maintain existing logic and state-based UI.
    *   **Uploading (Index 3):** Placeholder for a future screen.
    *   **User (Index 4):** Navigate to Profile (`_onProfilePressed` from `TranscriptListScreen` logic).
*   **Styling:** Maintain the app's dark theme (`Color(0xFF101822)`).

## 3. Implementation Guide

### A. Widget Structure

To ensure the Bottom Navigation Bar remains visible when switching tabs, we must not use `context.push`. Instead, we will use a "Single Page" architecture where the `Scaffold` remains constant, and we switch the `body` content based on the selected index.

1.  **Extract Recording Content:** Move the current recording UI (everything inside the `BlocListener/BlocBuilder` for the recording interface) into a separate widget or method, e.g., `_RecordingView`.
2.  **Define Pages:** Create a list of widgets corresponding to each tab.
3.  **Switch Body:** Update the `Scaffold` body to display the widget from the list matching the current `_page` index.

```dart
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../transcription/presentation/pages/transcript_list_screen.dart'; // Import for History Tab
// ... other imports

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _page = 2; // Default to Record tab

  // Define the pages for each tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // Index 0: History (Folder)
      // Note: You might need to adjust TranscriptListScreen to hide its back button if used as a tab.
      const TranscriptListScreen(), 
      
      // Index 1: Import
      const Center(child: Text("Import Screen Placeholder")), // Replace with actual import logic/screen if needed
      
      // Index 2: Recording (The main view)
      const _RecordingView(),
      
      // Index 3: Uploading
      const Center(child: Text("Uploading Screen Placeholder")),
      
      // Index 4: Profile
      // You can reuse ProfileScreen here if available, or a placeholder
      const Center(child: Text("Profile Screen Placeholder")),
    ];
  }

  // Handle Bottom Bar Taps
  void _onBottomNavTapped(int index) {
    setState(() {
      _page = index;
    });
    // Note: Special logic for "Import" (Index 1) might still be needed here
    // if it's an action rather than a screen (e.g., opening a file picker).
    // If it's a screen, just letting setState update the body is sufficient.
    if (index == 1) {
       // logic for import if it's not a persistent screen
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the specific Recording View with the BlocListener, 
    // or wrap the whole Scaffold if the Bloc is needed globally.
    // Assuming Bloc is needed for the FAB/Center button state:
    return BlocBuilder<RecordingBloc, RecordingState>(
      builder: (context, state) {
        final isRecording = state is RecordingInProgress;
        final isPaused = state is RecordingPaused;

        return Scaffold(
          backgroundColor: const Color(0xFF101822),
          
          // Use IndexedStack to preserve state of tabs, or just _pages[_page] to rebuild
          body: IndexedStack(
            index: _page,
            children: _pages,
          ),

          bottomNavigationBar: CurvedNavigationBar(
            key: _bottomNavigationKey,
            index: 2,
            height: 75.0,
            items: <Widget>[
              const Icon(Icons.folder_outlined, size: 30, color: Colors.white),
              const Icon(Icons.file_upload_outlined, size: 30, color: Colors.white),
              
              // Center Record Button
              Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isRecording ? 48 : 44,
                      height: isRecording ? 48 : 44,
                      decoration: BoxDecoration(
                        color: isPaused ? const Color(0xFF282E39) : const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: isRecording ? 0.4 : 0.2),
                            blurRadius: isRecording ? 12 : 8,
                            spreadRadius: isRecording ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isRecording ? Icons.stop : isPaused ? Icons.play_arrow : Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                  ],
                ),

              const Icon(Icons.cloud_upload_outlined, size: 30, color: Colors.white),
              const Icon(Icons.person_outline, size: 30, color: Colors.white),
            ],
            color: const Color(0xFF282E39),
            buttonBackgroundColor: const Color(0xFF282E39),
            backgroundColor: const Color(0xFF101822),
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 600),
            onTap: (index) {
                // Special handling for the Center Button (Index 2) to trigger Record Action
                // If the user taps the center button while already on the recording tab, 
                // we might want to trigger the action (Start/Stop).
                if (index == 2 && _page == 2) {
                     if (state is RecordingInProgress) {
                        context.read<RecordingBloc>().add(const StopRecordingRequested());
                     } else if (state is RecordingPaused) {
                        context.read<RecordingBloc>().add(const ResumeRecordingRequested());
                     } else {
                        context.read<RecordingBloc>().add(const StartRecordingRequested());
                     }
                }
                _onBottomNavTapped(index);
            },
            letIndexChange: (index) => true,
          ),
        );
      }
    );
  }
}

// ... Create _RecordingView widget containing the original RecordingPage body content
class _RecordingView extends StatelessWidget {
    const _RecordingView();
    
    @override
    Widget build(BuildContext context) {
        // ... The original column with Timer, Status Text, etc.
        // DO NOT include the Bottom Navigation Bar here.
        return Container(
             // ...
        );
    }
}
```

### B. Key Style Requirements

1.  **Seamless Integration:** The `backgroundColor` of the `CurvedNavigationBar` **MUST** match the `Scaffold` background (`Color(0xFF101822)`) to create the "cut-out" effect.
2.  **Icon Style:** Use `_outlined` icons where possible to match the requested modern aesthetic.
3.  **Center Button:** The center icon (Record) is larger (`size: 40`) and changes color/icon based on the recording state (Red/Stop when recording, Blue/Circle when idle).
4.  **Theme Consistency:** The bar color (`color`) and button circle color (`buttonBackgroundColor`) use the app's secondary dark shade (`Color(0xFF282E39)`).
