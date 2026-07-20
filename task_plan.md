# Project Task Plan - Go Fast Grocery

This plan details the features and implementation steps for the User Profile Completion & Registration Flow for all 3 roles (Customer, Shopkeeper, Rider).

## Current Task Focus
- [x] Standardize and redesign Customer, Shopkeeper, and Rider signup portals to use identical premium visual styles (atmospheric blurs, rounded card panels, tab selections).
- [x] Integrate full registration fields on both the initial Sign Up forms (`signup_screen.dart`) and the profile completion forms (`customer_registration_screen.dart`, `shopkeeper_registration_screen.dart`, `rider_registration_screen.dart`).
- [x] Auto-register cached fields from secure storage after OTP verification.
- [x] Compile and verify static analyzer integrity with zero errors.
- [x] Implement the `CustomerDashboard` screen with custom Appbar delivery address picker, search bar, promotional banner carousel, category selector, nearby approved shops listing, and bottom navigation.
- [x] Navigate from Shop Card on `CustomerDashboard` to `ShopMenuScreen`, implementing custom horizontal category tabs, searchable shop product listing with reactive `CartBloc` counter buttons, and bottom sticky Floating View Cart indicator.
- [x] Enforce Single-Shop Cart Rule: Modified `Product` entities/models, extended `CartBloc` events and states to capture basket conflicts, and created custom Warning Dialog popup in `ShopMenuScreen` to handle cart clears reactively.
- [x] Implement the `CheckoutScreen` UI: Configured custom AppBar with Back, Delivery Location edit overlay, cart items list with reactive quantity steppers, bill summary receipt (Subtotal, Rs. 100 delivery fee, Grand Total), default Cash on Delivery method highlight, and sticky "Place Order" button at bottom.
- [x] Configure Order Placement & Success Flow: Enhanced `OrderSuccessScreen` with animated icon scales, custom congratulatory messages ("Your order is sent to the shop!"), custom Order ID format (`#GFG-1029`), and routing buttons to track orders or return home.
- [x] Implement `ShopkeeperDashboard`: Configured bottom navigation bar with Orders, My Menu, and Profile tabs. Added dynamic OrderCard widgets with pulsing glow alerts for 'Pending' orders, acceptance controls (Accept/Reject actions), and active preparation pipelines.
- [x] Configure Shopkeeper Accept & Broadcast Logic: Added BLoC events (`AcceptOrderEvent`, `FindRiderEvent`) and states (`OrderAcceptedSuccess`, `FindingRiderProgress`, `FindingRiderSuccess`). Built time quick-select dialog and simulated circular radar overlay for broadcasting notifications to nearby riders.
- [x] Implement `RiderDashboard`: Setup AppBar status toggle switcher (Online/Offline), custom MapPainter with simulated street avenues/grid routes, and visually loud animated `IncomingRequestCard` bottom-sheet presenting pickup/drop-off details, COD collection rates, and estimated trip earnings.
- [x] Enforce Rider COD Limit Security Rule: Checked `cod_amount` limits (> Rs. 5000) to block automatic delivery acceptances, showing a warning card and "Request Admin Approval" button instead. Added BLoC state transitions (`AdminApprovalProgress`, `AdminApprovalSuccess`) with 3 seconds simulated clearance spinners.
- [x] Build `ActiveDeliveryScreen`: Implemented simulated route map navigation, revealed previously hidden contact numbers and exact street addresses, and coded swipe-to-start-trip and swipe-to-deliver slider controls.
- [x] Implement Bilingual Localization Support: Created `LanguageBloc` and `AppTranslations` dictionary matching English and Urdu localization codes. Registered JamilNooriNastaleeq font assets in `pubspec.yaml`, provided the blocs globally, and created action toggle chips in `RoleSelectionScreen`.











## Next Milestone tasks
- [ ] Connect Google Maps API key for Map Pin location mapping in production.
- [ ] Implement actual image uploading to a cloud storage provider (e.g., S3, Cloudinary) or backend multi-part forms instead of local file paths.
- [ ] Support verification panel in the Admin dashboard for approving pending shopkeepers and riders.
- [ ] Enable real-time push notifications for profile status updates (incomplete -> approved / rejected).
