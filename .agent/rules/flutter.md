---
trigger: always_on
---

To achieve a completely fluid layout in Flutter without hardcoding values, the rule you must follow is Constraints-Based Design, and the core principle is: Constraints flow down, sizes flow up.
In this paradigm, the parent defines the boundaries (constraints), and the child decides its size within those bounds. 
The Rule: "Use Relative Scaling & Constraints" 
The single most important rule is to never use fixed double values (like width: 300) for layout-critical elements. Instead, use widgets that calculate space dynamically based on the parent's box constraints. 
4 Key Widgets to Achieve This
LayoutBuilder: This is the "brain" of a responsive widget. It provides the BoxConstraints of the parent, allowing you to use if/else logic to return different widget trees (e.g., a Row for desktop or a Column for mobile) based on maxWidth.
Flexible & Expanded: These are essential for preventing overflows. They tell a child to take up only the available space in a Row or Column rather than its "natural" (and potentially too large) size.
FractionallySizedBox: This allows you to define a widget's size as a percentage of its parent (e.g., widthFactor: 0.5 for exactly 50% width).
AspectRatio: Instead of setting a height and width, you set a ratio (like 16/9). This ensures the widget scales up or down without ever "squashing" or distorting. 
Adaptive vs. Responsive
Responsive: The layout stretches, shrinks, or rearranges (e.g., using Wrap instead of Row).
Adaptive: The app changes behavior or components based on the platform (e.g., showing a Cupertino slider on iOS and a Material slider on Android). 
Best Practice
Instead of manual math, use the MediaQuery.sizeOf(context) to get the device dimensions and combine it with a Breakpoint system (defining specific widths where your layout "breaks" and reshapes). 

