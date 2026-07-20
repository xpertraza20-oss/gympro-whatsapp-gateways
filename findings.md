# Architectural Findings & Decisions - Go Fast Grocery

This file lists key insights, architectural details, and troubleshooting notes for the onboarding flow.

## 1. Onboarding State Pipeline
We use a hybrid approach to make registration smooth:
- **Pre-auth Secure Storage**: When a user registers a new account (e.g. as a Rider or Shopkeeper), they enter all details immediately. To avoid losing these inputs during the intermediate SMS/OTP verification screen, all inputs (including document file paths) are stored temporarily in `FlutterSecureStorage` under the prefix `temp_`.
- **Post-auth Auto-submit**: When the OTP verification successfully triggers, the app navigates the user to their respective registration screen based on their role. In `initState`, the screen detects the presence of cached parameters, dispatches the registration BLoC event automatically in the background, and seamlessly bypasses manual entry for a fast, frictionless experience.

## 2. API Design Decisions
- The authentication remote data source (`AuthRemoteDataSource`) returns a `profile_status` object upon OTP validation:
  ```json
  {
    "is_complete": false,
    "status": "incomplete"
  }
  ```
- If the status is `'incomplete'`, the mobile app routes to completion forms. If `'pending'`, it routes to the Pending Approval screen. If `'complete'`, the user enters their main dashboard.

## 3. UI Styling Rules
- **Customer Portal**: Green (`Color(0xFF006E2F)` / `Color(0xFF065F34)`) theme accents.
- **Shopkeeper Portal**: Orange/Amber (`Color(0xFFBA5F06)` / `Color(0xFF064E3B)`) theme accents.
- **Rider Portal**: Teal (`Color(0xFF0F766E)`) theme accents.
- All screens use positioned atmospheric blurs in the background to present a consistent, gorgeous, premium visual look.

## 4. Multi-Vendor Dashboard Design
- **Shop-Centric Architecture**: Unlike typical single-store apps, `CustomerDashboard` is structured around *Shops* rather than products. Users select a shop first to view its specific menu/catalog.
- **Horizontal Filtering & Banners**: The search bar acts as a unified entry point, backed by horizontal promotional banner cards and a circular category chip list (`Grocery`, `Pharmacy`, `Meat`, `Dairy`, etc.) that filters the shops below in real-time.
- **Sliver Implementation**: We use a `CustomScrollView` with a floating `SliverAppBar` to maximize screen real estate when scrolling the vertical list of nearby approved shops.

## 5. Shop Menu & State Management
- **Decoupled Data Flow**: To keep the dashboard and product catalog modules separated, the transition maps `ShopModel` to `ShopMenuData` upon navigation, avoiding tight coupling or circular dependencies.
- **Reactive Cart Syncing**: The `ProductCard` widget listens to the global `CartBloc` state. If a product's ID is found in the cart list, it replaces the "Add" button with a stepper controller, dispatching `UpdateQuantityEvent` to synchronize quantity adjustments.
- **Sticky Cart Overlay**: A bottom-floating CTA card is shown conditionally using `BlocBuilder` only when the active cart's item count is greater than zero, displaying subtotals dynamically.

## 6. Single-Shop Cart Enforcement
- **Product Entity Shop Bounds**: Added `shopId` and `shopName` to `Product` properties to track the origin shop of items.
- **State-driven Conflict Alerts**: Rather than displaying dialogs directly in controllers, we leverage BLoC. If a user adds an item from Shop B while their cart has items from Shop A, `CartBloc` yields `pendingProduct` and `conflictShopName` in the state.
- **Transient UI Hooks**: `ShopMenuScreen` uses a `BlocListener` to present the warning dialog. Actioning "Clear Cart & Add" dispatches a `ClearAndAddEvent` that replaces the cart with the pending item and resets conflict flags.

## 7. Checkout & Invoice Calculation
- **Secure Storage Fallbacks**: Pre-populates location data from `FlutterSecureStorage` (read key `user_location` or `temp_location`) and supports on-the-fly edit/phone update dialog overrides.
- **Dynamic Bill Adjustments**: Quantity steppers inside `CheckoutScreen` bind directly to `CartBloc`, which updates state items instantly. This updates the bill summary receipt and bottom sticky button's grand total in real-time.

## 8. Order Success Animations & Routing
- **Spring Scale Transitions**: `OrderSuccessScreen` utilizes a `SingleTickerProviderStateMixin` and `ScaleTransition` to spring the green confirmation badge with bounce effects.
- **Cart Reset Triggers**: Checkout listens to `OrderPlacedSuccess`. When intercepted, it dispatches `ClearCartEvent` to clear the basket and prevent duplicate submissions.

## 9. Shopkeeper Order Alerts & Pipelines
- **Pulsing Border Glow Effects**: Used `AnimationController` inside a stateful widget to pulse the card border radius drop shadows dynamically, highlighting incoming 'Pending' alerts.
- **Preparing & Ready States**: Accept dispatches local state modifications changing state items to "Preparing" (renders "Mark Ready" button) and "Ready" (displays green "Waiting for Rider" tag).

## 10. Shopkeeper Acceptance & Broadcasting
- **Prep Time Selection Dialog**: Intercepts accept trigger to display a choice dialog mapping 10, 20, 30, and 45 minutes chips.
- **Rider Sonar Broadcasting Overlay**: FindingRiderProgress triggers a Stack-level full-screen modal showing a spinning circular sonar overlay with radar iconography, holding for 3 seconds before marking order state as 'Looking for Rider'.

## 11. Rider Map Rendering & Ringing Overlays
- **Custom Road Grid Canvas**: Implemented custom 2D vector path painting in `MapPainter` drawing structured avenues, cross streets, park boundaries, and routing paths to avoid heavy web dependencies.
- **Ringing Bottom Sheet Scale Transition**: Used elastic scale and pulsing opacity keyframes to alert riders visually to incoming orders without disturbing dashboard navigation.
- **Exact Address Security**: Hidden exact customer house details and contacts inside incoming cards, revealing them only post-acceptance.

## 12. COD Limit Security & Active Delivery Transitions
- **Interactive COD Limit Check**: Enforces a strict security rule checking if `cod_amount` exceeds Rs. 5000. Under limit shows normal green accept button; over limit hides accept action and requires admin override authorization.
- **Admin Override BLoC Cycles**: Dispatches `RequestAdminApprovalEvent` yielding `AdminApprovalProgress` loading barrier, resolving in 3 seconds to `AdminApprovalSuccess` to unlock access.
- **Swipe-to-Action Gestures**: Coded horizontal swipe gesture trackers in `ActiveDeliveryScreen`. Swipe transitions dynamically from start trip to drop-off completion, executing BLoC states sequentially.

## 13. Bilingual Localization & Jamil Noori Nastaleeq Styling
- **SharedPreferences Language Caching**: Preferred language preferences (EN or UR) are cached inside SharedPreferences and auto-reloaded on start.
- **Nastaleeq Vertical Spacing Compensations**: Urdu text requires custom visual adjustments due to tall cursive script paths. We intercept text style evaluations through context extensions to scale `fontSize` by 15% and inflate `height` by 50% using `JamilNooriNastaleeq` to prevent vertical line clipping.
- **RTL Directional Swaps**: Wrapped role lists and text components with `Directionality(textDirection: context.textDirection)` to swap layouts from right-to-left dynamically based on locale.










